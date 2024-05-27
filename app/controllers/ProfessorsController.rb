# app/controllers/professors_controller.rb
class ProfessorsController < ApplicationController
  skip_forgery_protection
  
  def initialize
    @professor_collection = ProfessorCollection.new
    @user_collection = UserCollection.new
  end

  def create
    professor_data = {
      code: @professor_collection.generate_unique_code(params[:campus]),
      full_name: params[:full_name],
      email: params[:email],
      office_phone: params[:office_phone],
      cellphone: params[:cellphone],
      status: params[:status] || 'active',
      coordinator: false,
      campus: params[:campus],
      photo: params[:photo]
    }
    
    begin
      professor = @professor_collection.create(professor_data)
      
      user_data = {
        email: params[:email],
        full_name: params[:full_name],
        role: User::ROLES[:professor],
        campus: params[:campus]
      }
      
      result = @user_collection.create_with_password(user_data)
      user = result[:user]
      password = result[:password]
      
      professor_data[:user_id] = user[:id]
      professor_ref = @professor_collection.update(professor[:id], professor_data)
      
      ProfessorMailer.welcome_email(professor_ref, user[:email], password).deliver_now
      
      modified_by_user_id = params[:modified_by_user_id]
      ProfessorModification.create(
        professor_code: professor_ref[:code],
        modified_by: modified_by_user_id,
        modification_type: 'Creación',
        new_data: professor_ref
      )
      
      render json: professor_ref, status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def update
    code = params[:code]
    professor_data = {
      full_name: params[:full_name],
      email: params[:email],
      office_phone: params[:office_phone],
      cellphone: params[:cellphone],
      status: params[:status],
      campus: params[:campus],
      coordinator: ActiveModel::Type::Boolean.new.cast(params[:coordinator]),
      photo: params[:photo]
    }
    
    begin
      professor = @professor_collection.update(code, professor_data)
      
      if professor.present?
        new_password = SecureRandom.base64(10)
        @user_collection.update_password(professor[:user_id], new_password)
        
        ProfessorMailer.credentials_email(professor, professor[:email], new_password).deliver_now
        
        modified_by_user_id = params[:modified_by_user_id]
        ProfessorModification.create(
          professor_code: professor[:code],
          modified_by: modified_by_user_id,
          modification_type: 'Actualización',
          previous_data: @professor_collection.find_by_code(code),
          new_data: professor
        )
        
        render json: professor
      else
        render json: { error: 'Professor not found' }, status: :not_found
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
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
      campus: params[:campus],
      photo: params[:photo]
    }
    
    new_password = params[:new_password]
    
    begin
      professor = @professor_collection.update(code, professor_data)
      
      if professor.present?
        if new_password.present?
          @user_collection.update_password(professor[:user_id], new_password)
        end
        
        if professor_data[:email].present? && professor_data[:email] != professor[:email] || new_password.present?
          ProfessorMailer.credentials_email(professor, professor[:email], new_password).deliver_now
        end
        
        render json: professor
      else
        render json: { error: 'Professor not found' }, status: :not_found
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def toggle_coordinator
    code = params[:code]
    
    begin
      professor = @professor_collection.toggle_coordinator(code)
      
      if professor.present?
        render json: professor
      else
        render json: { error: 'Professor not found' }, status: :not_found
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def search
    query = params[:query]
    professors = @professor_collection.search(query)
    
    if professors.empty?
      render json: { message: 'No se encontraron profesores que coincidan con la búsqueda' }, status: :not_found
    else
      render json: professors
    end
  end

  def get_professor
    code = params[:code]
    professor = @professor_collection.find_by_code(code)
    
    if professor.present?
      render json: professor
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def get_photo
    code = params[:code]
    professor = @professor_collection.find_by_code(code)
    
    if professor.present?
      if professor[:photo_url].present?
        redirect_to professor[:photo_url]
      else
        render json: { error: 'Professor does not have a photo' }, status: :not_found
      end
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def get_professor_by_email
    email = params[:email]
    professor = @professor_collection.find_by_email(email)
    
    if professor.present?
      render json: professor
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def get_professors_by_campus
    campus = params[:campus]
    professors = @professor_collection.find_by_campus(campus)
    
    if professors.empty?
      render json: { message: 'No professors found for the specified campus' }, status: :not_found
    else
      render json: professors
    end
  end

  def get_active_professors
    professors = @professor_collection.find_active
    
    if professors.empty?
      render json: { message: 'No active professors found' }, status: :not_found
    else
      render json: professors
    end
  end

  def get_inactive_professors
    professors = @professor_collection.find_inactive
    
    if professors.empty?
      render json: { message: 'No inactive professors found' }, status: :not_found
    else
      render json: professors
    end
  end

  def get_professor_user
    code = params[:code]
    user = @professor_collection.find_user(code)
    
    if user.present?
      render json: user
    else
      render json: { error: 'User not found for the professor' }, status: :not_found
    end
  end
end