class ProfessorsController < ApplicationController
  skip_forgery_protection

  ## Crear Profesor
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
      # Generar una contraseña aleatoria para el usuario
      password = SecureRandom.base64(10)
      
      user_data = {
        email: params[:email],
        full_name: params[:full_name],
        role: User::ROLES[:professor],
        campus: params[:campus],
        password: encrypt_password(password)
      }
      
      user = create_user(user_data)
      
      if user.present?
        professor.user_id = user[:id]
        
        professor_ref = create_professor(professor)
        if professor_ref.present?
          send_welcome_email(professor, user[:email], password)
          
          # Obtener el ID del usuario que realiza la modificación desde los parámetros
          modified_by_user_id = params[:modified_by_user_id]
          
          # Guardar registro de modificación
          ProfessorModification.create(
            professor_code: professor.code,
            modified_by: modified_by_user_id,
            modification_type: 'Creación',
            new_data: professor_ref.data
          )
          
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

  ## Modificar el usuario para la asistente administrativa (Si lo modifica se reinicia la contraseña del profesor)
  def update
    code = params[:code]
    professor_data = {
      full_name: params[:full_name],
      email: params[:email],
      office_phone: params[:office_phone],
      cellphone: params[:cellphone],
      status: params[:status],
      campus: params[:campus] # Agregar el atributo campus al hash professor_data
    }
    
    # Convertir el valor de 'coordinator' a booleano
    if params[:coordinator].present?
      coordinator = ActiveModel::Type::Boolean.new.cast(params[:coordinator])
      professor_data[:coordinator] = coordinator
    end
    
    photo = params[:photo]
    if photo.present?
      photo_url = upload_photo(photo)
      professor_data[:photo_url] = photo_url
    end
    
    professor = FirestoreDB.col('professors').where('code', '==', code).get.first
    if professor.present?
      professor_ref = professor.ref
      previous_data = professor.data
      
      email_changed = false
      campus_changed = false
      
      # Verificar si el correo electrónico ya está en uso por otro profesor
      if professor_data[:email].present? && professor_data[:email] != professor.data[:email]
        existing_professor = FirestoreDB.col('professors').where('email', '==', professor_data[:email]).get.first
        if existing_professor.present?
          render json: { error: 'Email already exists' }, status: :unprocessable_entity
          return
        else
          email_changed = true
        end
      end
      
      # Verificar si el campus ha cambiado
      if professor_data[:campus].present? && professor_data[:campus] != professor.data[:campus]
        campus_changed = true
      end
      
      # Actualizar los atributos del profesor
      professor_data.each do |key, value|
        professor_ref.update({ key => value }) if value.present?
      end
      
      # Obtener el profesor actualizado desde Firestore
      updated_professor = professor_ref.get
      
      # Obtener el usuario asociado al profesor
      user_id = updated_professor.data[:user_id]
      user_doc = FirestoreDB.col('users').doc(user_id).get
      
      if user_doc.exists?
        user_data = user_doc.data
        updated_user_data = {}
        
        # Generar una nueva contraseña para el usuario
        new_password = SecureRandom.base64(10)
        
        # Encriptar la nueva contraseña
        encrypted_password = encrypt_password(new_password)
        
        # Agregar la contraseña actualizada al nuevo hash
        updated_user_data[:password] = encrypted_password
        
        # Actualizar el correo electrónico del usuario si ha cambiado
        if email_changed
          updated_user_data[:email] = professor_data[:email]
        end
        
        # Actualizar el campus del usuario si ha cambiado
        if campus_changed
          updated_user_data[:campus] = professor_data[:campus]
        end
        
        # Combinar los datos existentes con los datos actualizados
        updated_user_data = user_data.merge(updated_user_data)
        
        user_doc.ref.set(updated_user_data)
        
        # Enviar correo electrónico con las nuevas credenciales
        ProfessorMailer.credentials_email(updated_professor.data, updated_user_data[:email], new_password).deliver_now
      end
      
      # Obtener el ID del usuario que realiza la modificación desde los parámetros
      modified_by_user_id = params[:modified_by_user_id]
      
      # Guardar registro de modificación
      ProfessorModification.create(
        professor_code: updated_professor.data[:code],
        modified_by: modified_by_user_id,
        modification_type: 'Actualización',
        previous_data: previous_data,
        new_data: updated_professor.data
      )
      
      render json: updated_professor.data.merge(id: updated_professor.document_id)
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end
  
  def update_profile
  code = params[:code]
  professor_data = {
    full_name: params[:full_name],
    email: params[:email],
    office_phone: params[:office_phone],
    cellphone: params[:cellphone],
    status: params[:status],
    campus: params[:campus] # Agregar el atributo campus al hash professor_data
  }
  
  new_password = params[:new_password]
  
  photo = params[:photo]
  if photo.present?
    photo_url = upload_photo(photo)
    professor_data[:photo_url] = photo_url
  end
  
  professor = FirestoreDB.col('professors').where('code', '==', code).get.first
  if professor.present?
    professor_ref = professor.ref
    
    email_changed = false
    campus_changed = false
    
    # Verificar si el correo electrónico ya está en uso por otro profesor
    if professor_data[:email].present? && professor_data[:email] != professor.data[:email]
      existing_professor = FirestoreDB.col('professors').where('email', '==', professor_data[:email]).get.first
      if existing_professor.present?
        render json: { error: 'Email already exists' }, status: :unprocessable_entity
        return
      else
        email_changed = true
      end
    end
    
    # Verificar si el campus ha cambiado
    if professor_data[:campus].present? && professor_data[:campus] != professor.data[:campus]
      campus_changed = true
    end
    
    # Actualizar los atributos del profesor
    professor_data.each do |key, value|
      professor_ref.update({ key => value }) if value.present?
    end
    
    # Obtener el profesor actualizado desde Firestore
    updated_professor = professor_ref.get
    
    # Obtener el usuario asociado al profesor
    user_id = updated_professor.data[:user_id]
    user_doc = FirestoreDB.col('users').doc(user_id).get
    
    if user_doc.exists?
      user_data = user_doc.data
      updated_user_data = {}
      
      if new_password.present?
        # Encriptar la nueva contraseña
        encrypted_password = encrypt_password(new_password)
        
        # Agregar la contraseña actualizada al nuevo hash
        updated_user_data[:password] = encrypted_password
      end
      
      if email_changed
        updated_user_data[:email] = professor_data[:email]
      end
      
      if campus_changed
        updated_user_data[:campus] = professor_data[:campus]
      end
      
      # Combinar los datos existentes con los datos actualizados
      updated_user_data = user_data.merge(updated_user_data)
      
      user_doc.ref.set(updated_user_data)
      
      if email_changed || new_password.present?
        # Enviar correo electrónico con las credenciales actualizadas
        ProfessorMailer.credentials_email(updated_professor.data, updated_user_data[:email], new_password).deliver_now
      end
    end
    
    render json: updated_professor.data
  else
    render json: { error: 'Professor not found' }, status: :not_found
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

  def toggle_coordinator
    code = params[:code]
    professor = FirestoreDB.col('professors').where('code', '==', code).get.first
    
    if professor.present?
      professor_ref = professor.ref
      
      if professor.data[:coordinator]
        # Desactivar el estado de coordinador
        professor_ref.update({ coordinator: false })
      else
        # Verificar si ya existe otro profesor coordinador en el mismo campus
        campus = professor.data[:campus]
        existing_coordinator = FirestoreDB.col('professors')
                                           .where('campus', '==', campus)
                                           .where('coordinator', '==', true)
                                           .get.first
        
        if existing_coordinator.present?
          render json: { error: 'Another professor is already assigned as coordinator for this campus' }, status: :unprocessable_entity
          return
        end
        
        # Activar el estado de coordinador
        professor_ref.update({ coordinator: true })
      end
      
      # Obtener el profesor actualizado desde Firestore
      updated_professor = professor_ref.get
      
      render json: updated_professor.data.merge(id: updated_professor.document_id)
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  #### Métodos Get

  def search
    query = params[:query]&.downcase
  
    if query.present?
      professors = FirestoreDB.col('professors').get.to_a
      matching_professors = professors.select do |prof|
        prof.data.values.any? { |value| value.to_s.downcase.include?(query) }
      end
  
      if matching_professors.empty?
        render json: { message: 'No se encontraron profesores que coincidan con la búsqueda' }, status: :not_found
      else
        render json: matching_professors.map { |prof| prof.data.merge(id: prof.document_id) }
      end
    else
      professors = FirestoreDB.col('professors').get.to_a
  
      if professors.empty?
        render json: { message: 'No se encontraron profesores' }, status: :not_found
      else
        render json: professors.map { |prof| prof.data.merge(id: prof.document_id) }
      end
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

  private
  def encrypt_password(password)
    BCrypt::Password.create(password)
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

  def upload_photo(photo)
    file_path = "professors/#{SecureRandom.uuid}/#{photo.original_filename}"
    bucket_name = 'projecto-diseno-backend.appspot.com'
    bucket = FirebaseStorage.bucket(bucket_name)
    file_obj = bucket.create_file(photo.tempfile, file_path, content_type: photo.content_type)
    file_obj.public_url
  end

end