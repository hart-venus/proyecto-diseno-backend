class ProfessorsController < ApplicationController
  skip_forgery_protection
  before_action :set_professor, only: [:show, :update, :activate, :deactivate, :set_coordinator, :remove_coordinator, :upload_photo]

  def index
    if FirestoreDB.collection_group('professors').get.empty?
      render json: { message: 'No professors found' }, status: :not_found
    else
      professors = FirestoreDB.col('professors').get
      render json: professors.map { |prof| prof.data.merge(id: prof.document_id) }
    end
  end

  def show
    if @professor.present?
      render json: @professor.data.merge(id: @professor.document_id)
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def create
    existing_user = FirestoreDB.col('users').where('email', '==', params[:email]).get.first
    existing_professor = FirestoreDB.col('professors').where('email', '==', params[:email]).get.first
  
    if existing_user.present? || existing_professor.present?
      render json: { error: 'Email already exists' }, status: :unprocessable_entity
      return
    end
  
    password = SecureRandom.base64(10)
    user_data = {
      email: params[:email],
      full_name: params[:full_name],
      role: User::ROLES[:professor],
      campus: params[:campus],
      password: password
    }
  
    user = UsersController.new.create_user(user_data)
  
    if user.present?
      professor_data = {
        code: generate_unique_code(params[:campus]),
        full_name: params[:full_name],
        email: params[:email],
        office_phone: params[:office_phone],
        cellphone: params[:cellphone],
        photo_url: params[:photo_url],
        status: params[:status],
        coordinator: params[:coordinator],
        user_id: user[:id],
        campus: params[:campus]
      }
  
      professor_ref = FirestoreDB.col('professors').add(professor_data)
      professor = professor_ref.get
      professor_data = professor.data.merge(id: professor.document_id)
      professor_model = Professor.new(professor_data)
  
      if professor_model.valid?
        begin
          send_welcome_email(professor_model, user[:email], password)
          render json: professor_model.attributes, status: :created
        rescue => e
          # Manejar el error del envío de correo electrónico
          Rails.logger.error("Failed to send welcome email to professor: #{professor_model.inspect}")
          Rails.logger.error("Error: #{e.message}")
          render json: { error: 'Professor created, but failed to send welcome email' }, status: :created
        end
      else
        UsersController.new.destroy(user[:id])
        render json: { errors: professor_model.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Failed to create user' }, status: :unprocessable_entity
    end
  rescue => e
    UsersController.new.destroy(user[:id]) if user.present?
    Rails.logger.error("Failed to create professor: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { error: 'An error occurred while creating the professor', details: e.message }, status: :internal_server_error
  end

  def update
    if @professor.present?
      professor_data = @professor.data.dup
      professor_params.each do |key, value|
        professor_data[key.to_sym] = value if professor_data.key?(key.to_sym)
      end
      professor_data[:updated_at] = Time.now
      @professor.ref.set(professor_data)
      render json: professor_data.merge(id: @professor.document_id)
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def activate
    if @professor.present?
      @professor.ref.update(status: 'active', updated_at: Time.now)
      render json: { message: 'Professor activated' }
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def deactivate
    if @professor.present?
      @professor.ref.update(status: 'inactive', updated_at: Time.now)
      render json: { message: 'Professor deactivated' }
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def find_by_campus
    campus = params[:campus]
    professors = FirestoreDB.col('professors').where('campus', '==', campus).get
    render json: professors.map { |prof| prof.data.merge(id: prof.document_id) }
  end

  def find_by_status
    status = params[:status]
    professors = FirestoreDB.col('professors').where('status', '==', status).get
    render json: professors.map { |prof| prof.data.merge(id: prof.document_id) }
  end

  def find_by_code
    code = params[:code]
    professor = FirestoreDB.col('professors').where('code', '==', code).limit(1).get.first
    if professor.present?
      render json: professor.data.merge(id: professor.document_id)
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def set_coordinator
    if @professor.present?
      @professor.ref.update(coordinator: true, updated_at: Time.now)
      render json: { message: 'Professor set as coordinator' }
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def remove_coordinator
    if @professor.present?
      @professor.ref.update(coordinator: false, updated_at: Time.now)
      render json: { message: 'Professor removed as coordinator' }
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def upload_photo
    if @professor.present?
      file = params[:file]
      if file.present?
        destination_path = "professors/#{@professor.document_id}/photo.#{file.original_filename.split('.').last}"
        photo_url = StorageService.instance.upload_file(file, destination_path)
        @professor.ref.update(photo_url: photo_url, updated_at: Time.now)
        render json: { message: 'Photo uploaded successfully', photo_url: photo_url }
      else
        render json: { error: 'No file provided' }, status: :bad_request
      end
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  private

  def set_professor
    @professor = FirestoreDB.col('professors').doc(params[:id]).get
  end

  def professor_params
    params.require(:professor).permit(:full_name, :email, :office_phone, :cellphone, :photo_url, :status, :coordinator, :campus)
  end

  def generate_unique_code
    "#{params[:campus]}-#{SecureRandom.uuid.split('-').first}"
  end

  def send_welcome_email(professor, user_email, user_password)
    ProfessorMailer.welcome_email(professor, user_email, user_password).deliver_now
  rescue => e
    Rails.logger.error("Failed to send welcome email to professor: #{professor.inspect}")
    Rails.logger.error("Error: #{e.message}")
  end
end