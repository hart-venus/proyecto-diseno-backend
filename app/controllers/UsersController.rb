# app/controllers/users_controller.rb
class UsersController < ApplicationController
  skip_forgery_protection

  def initialize
    @user_repository = UserCollection.new
  end

  def index
    users = @user_repository.all
    render json: users
  end

  def show
    user = @user_repository.find(params[:id])
    if user.present?
      render json: user
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  def create
    begin
      user = @user_repository.create(user_params)
      render json: user, status: :created
    rescue => e
      render json: { errors: e.message }, status: :unprocessable_entity
    end
  end

  def update
    begin
      user = @user_repository.update(params[:id], user_params)
      if user.present?
        render json: user
      else
        render json: { error: 'User not found' }, status: :not_found
      end
    rescue => e
      render json: { errors: e.message }, status: :unprocessable_entity
    end
  end

  def destroy
    begin
      @user_repository.delete(params[:id])
      head :no_content
    rescue => e
      render json: { errors: e.message }, status: :unprocessable_entity
    end
  end

  def authenticate
    email = params[:email]
    password = params[:password]

    user = @user_repository.authenticate(email, password)

    if user.present?
      render json: { message: 'Authentication successful', user_id: user[:id] }
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def recover_password
    email = params[:email]
    temporary_password = @user_collection.recover_password(email)
    
    if temporary_password.present?
      render json: { message: 'Temporary password sent to the registered email' }
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  def find_by_campus
    campus = params[:campus]
    unless validate_campus(campus)
      return
    end

    users = @user_repository.find_by_campus(campus)
    if users.empty?
      render json: { error: 'No users found for the specified campus' }, status: :not_found
    else
      render json: users
    end
  end

  def find_by_role
    role = params[:role]
    unless validate_role(role)
      return
    end

    users = @user_repository.find_by_role(role)
    if users.empty?
      render json: { error: 'No users found for the specified role' }, status: :not_found
    else
      render json: users
    end
  end

  def find_by_email
    email = params[:email]
    unless validate_email(email)
      return
    end

    user = @user_repository.find_by_email(email)
    if user.present?
      render json: user
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :full_name, :role, :campus, :password)
  end

  def validate_campus(campus)
    if Constants::CAMPUSES.key?(campus.to_sym)
      true
    else
      render json: { error: 'Invalid campus' }, status: :bad_request
      false
    end
  end

  def validate_role(role)
    if Constants::ROLES.value?(role)
      true
    else
      render json: { error: 'Invalid role' }, status: :bad_request
      false
    end
  end

  def validate_email(email)
    if email =~ URI::MailTo::EMAIL_REGEXP
      true
    else
      render json: { error: 'Invalid email format' }, status: :bad_request
      false
    end
  end
end