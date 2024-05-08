class ProfessorsController < ApplicationController
  skip_forgery_protection

  def create
    professor_data = {
      code: generate_unique_code(params[:campus]),
      full_name: params[:full_name],
      email: params[:email],
      office_phone: params[:office_phone],
      cellphone: params[:cellphone],
      status: params[:status] || 'active',
      coordinator: false,
      campus: params[:campus]
    }
  
    existing_professor = FirestoreDB.col('professors').where('email', '==', params[:email]).get.first
    if existing_professor.present?
      render json: { error: 'Email already exists' }, status: :unprocessable_entity
      return
    end
  
    photo = params[:photo]
    if photo.present?
      photo_url = upload_photo(photo)
      professor_data[:photo_url] = photo_url
    end
  
    professor = Professor.new(professor_data)
  
    if professor.valid?
      user_data = {
        email: params[:email],
        full_name: params[:full_name],
        role: User::ROLES[:professor],
        campus: params[:campus],
        password: SecureRandom.base64(10)
      }
      user = create_user(user_data)
  
      if user.present?
        professor.user_id = user[:id]
  
        professor_ref = create_professor(professor)
        if professor_ref.present?
          send_welcome_email(professor, user[:email], user_data[:password])
          render json: professor_ref.data.merge(id: professor_ref.document_id), status: :created
        else
          render json: { error: 'Failed to create professor' }, status: :unprocessable_entity
        end
      else
        render json: { error: 'Failed to create user' }, status: :unprocessable_entity
      end
    else
      render json: { errors: professor.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create_user(user_data)
    user = User.new(user_data)
    if user.valid?
      user_ref = FirestoreDB.col('users').add(user_data)
      user_doc = user_ref.get
      user_doc.data.merge(id: user_doc.document_id)
    else
      nil
    end
  end

  def create_professor(professor)
    professor_ref = FirestoreDB.col('professors').add(professor.attributes)
    professor_ref.get
  rescue Google::Cloud::InvalidArgumentError => e
    if e.message.include?('The query requires an index')
      index_creation_link = e.message.match(/https:\/\/.*/)
      if index_creation_link
        uri = URI(index_creation_link[0])
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.request_uri)
        response = http.request(request)
        if response.is_a?(Net::HTTPSuccess)
          professor_ref = FirestoreDB.col('professors').add(professor.attributes)
          professor_ref.get
        else
          Rails.logger.error("Failed to create index: #{response.body}")
          nil
        end
      else
        Rails.logger.error("Index creation link not found in the error message")
        nil
      end
    else
      Rails.logger.error("Firestore error: #{e.message}")
      nil
    end
  end

  def send_welcome_email(professor, user_email, user_password)
    ProfessorMailer.welcome_email(professor, user_email, user_password).deliver_now
    true
  rescue => e
    Rails.logger.error("Failed to send welcome email to professor: #{professor.inspect}")
    Rails.logger.error("Error: #{e.message}")
    false
  end

  def upload_photo(photo)
    file_path = "professors/#{SecureRandom.uuid}/#{photo.original_filename}"
    bucket_name = 'projecto-diseno-backend.appspot.com'
    bucket = FirebaseStorage.bucket(bucket_name)
    file_obj = bucket.create_file(photo.tempfile, file_path, content_type: photo.content_type)
    file_obj.public_url
  end

  def get_photo
    code = params[:code]
    validate_code(code)

    professor = FirestoreDB.col('professors').where('code', '==', code).get.first
    if professor.present?
      photo_url = professor.data[:photo_url]
      if photo_url.present?
        redirect_to photo_url
      else
        render json: { error: 'Professor does not have a photo' }, status: :not_found
      end
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def generate_unique_code(campus)
    campus_key = campus.to_sym
    if Professor::CAMPUSES.key?(campus_key)
      campus_code = Professor::CAMPUSES[campus_key]
      professors = FirestoreDB.col('professors').where('campus', '==', campus_code).order('code', 'desc').limit(1).get.to_a
      if professors.empty?
        "#{campus_code}-01"
      else
        last_professor_code = professors.first.data[:code]
        last_counter = last_professor_code.split('-').last.to_i
        new_counter = format('%02d', last_counter + 1)
        "#{campus_code}-#{new_counter}"
      end
    else
      raise ArgumentError, 'Invalid campus'
    end
  end

  #### Métodos Get

  def search
    query = params[:query].downcase
    if query.present?
      professors = FirestoreDB.col('professors').get.to_a
      matching_professors = professors.select do |prof|
        prof.data.values.any? { |value| value.to_s.downcase.include?(query) }
      end
      if matching_professors.empty?
        render json: { message: 'No professors found matching the query' }, status: :not_found
      else
        render json: matching_professors.map { |prof| prof.data.merge(id: prof.document_id) }
      end
    else
      render json: { error: 'Query parameter is missing' }, status: :bad_request
    end
  end
  
  def get_professor
    code = params[:code]
    validate_code(code)

    professor_doc = FirestoreDB.col('professors').where('code', '==', code)
    if professor_doc.present?
      render json: professor_doc.data.merge(id: professor_doc.document_id)
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end
  
  def get_professor_by_email
    email = params[:email]
    validate_email(email)

    professor_doc = FirestoreDB.col('professors').where('email', '==', email).get.first
    if professor_doc.present?
      render json: professor_doc.data.merge(id: professor_doc.document_id)
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end
  
  def get_professors_by_campus
    campus = params[:campus]
    validate_campus(campus)

    professors = FirestoreDB.collection("professors").where("campus", "==", "CA").get.to_a
    if professors.empty?
      render json: { message: 'No professors found for the specified campus' }, status: :not_found
    else
      render json: professors.map { |prof| prof.data.merge(id: prof.document_id) }
    end
  end
  
  def get_professors
    page = params[:page].to_i || 1
    limit = params[:limit].to_i || 10
    offset = (page - 1) * limit
    professors = FirestoreDB.col('professors').offset(offset).limit(limit).get
    if professors.empty?
      render json: { message: 'No professors found' }, status: :not_found
    else
      render json: professors.map { |prof| prof.data.merge(id: prof.document_id) }
    end
  end
  
  def get_active_professors
    professors = FirestoreDB.col('professors').where('status', '==', 'active').get
    if professors.empty?
      render json: { message: 'No active professors found' }, status: :not_found
    else
      render json: professors.map { |prof| prof.data.merge(id: prof.document_id) }
    end
  end
  
  def get_inactive_professors
    professors = FirestoreDB.col('professors').where('status', '==', 'inactive').get
    if professors.empty?
      render json: { message: 'No inactive professors found' }, status: :not_found
    else
      render json: professors.map { |prof| prof.data.merge(id: prof.document_id) }
    end
  end

  def get_professor_user
    code = params[:code]
    validate_code(code)

    professor_doc = FirestoreDB.col('professors').where('code', '==', code).get.first
    if professor_doc.present?
      user_id = professor_doc.data[:user_id]
      if user_id.present?
        user_doc = FirestoreDB.col('users').doc(user_id).get
        if user_doc.exists?
          render json: user_doc.data.merge(id: user_doc.document_id)
        else
          render json: { error: 'User not found for the professor' }, status: :not_found
        end
      else
        render json: { error: 'User not associated with the professor' }, status: :not_found
      end
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

   #### Métodos Put

   def update
    code = params[:code]
    professor_data = {
      full_name: params[:full_name],
      email: params[:email],
      office_phone: params[:office_phone],
      cellphone: params[:cellphone],
      status: params[:status]
    }
  
    photo = params[:photo]
    if photo.present?
      photo_url = upload_photo(photo)
      professor_data[:photo_url] = photo_url
    end
  
    professor = FirestoreDB.col('professors').where('code', '==', code).get.first
    if professor.present?
      professor_data.each do |key, value|
        professor.ref.update(key, value) if value.present?
      end
      render json: professor.data.merge(id: professor.document_id)
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  private

  def validate_code(code)
    unless code.present?
      render json: { error: 'Code parameter is missing' }, status: :bad_request
    end
  end

  def validate_email(email)
    unless email =~ URI::MailTo::EMAIL_REGEXP
      render json: { error: 'Invalid email format' }, status: :bad_request
    end
  end

  def validate_campus(campus)
    unless Professor::CAMPUSES.value?(campus)
      render json: { error: 'Invalid campus' }, status: :bad_request
    end
  end
end
