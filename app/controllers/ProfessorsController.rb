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
      coordinator: params[:coordinator] || false,
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
      user = UsersController.new.create_user(user_data)
  
      if user.present?
        professor.user_id = user[:id]
  
        begin
          professor_ref = FirestoreDB.col('professors').add(professor.attributes)
          professor_doc = professor_ref.get
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
                professor_doc = professor_ref.get
              else
                raise "Failed to create index: #{response.body}"
              end
            else
              raise "Index creation link not found in the error message"
            end
          else
            raise e
          end
        end
  
        begin
          send_welcome_email(professor, user[:email], user_data[:password])
          render json: professor_doc.data.merge(id: professor_doc.document_id), status: :created
        rescue => e
          Rails.logger.error("Failed to send welcome email to professor: #{professor.inspect}")
          Rails.logger.error("Error: #{e.message}")
          render json: { error: 'Professor created, but failed to send welcome email' }, status: :created
        end
      else
        render json: { error: 'Failed to create user' }, status: :unprocessable_entity
      end
    else
      render json: { errors: professor.errors.full_messages }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("Failed to create professor: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { error: 'An error occurred while creating the professor', details: e.message }, status: :internal_server_error
  end

  private

  def upload_photo(photo)
    file_path = "professors/#{SecureRandom.uuid}/#{photo.original_filename}"
    StorageService.instance.upload_file(photo.tempfile, file_path)
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

  def send_welcome_email(professor, user_email, user_password)
    ProfessorMailer.welcome_email(professor, user_email, user_password).deliver_now
  rescue => e
    Rails.logger.error("Failed to send welcome email to professor: #{professor.inspect}")
    Rails.logger.error("Error: #{e.message}")
  end
end