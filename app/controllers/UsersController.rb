class UsersController < ApplicationController
  skip_forgery_protection 
  def index
    users = FirestoreDB.col('users').get
    render json: users.map { |user| user.data.merge(id: user.document_id) }
  end

  def show
    user_ref = FirestoreDB.col('users').doc(params[:id])
    user = user_ref.get
    if user.exists?
      render json: user.data.merge(id: user.document_id)
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  def create
    user_data = {
      email: user_params[:email],
      full_name: user_params[:full_name],
      role: user_params[:role],
      campus: user_params[:campus],
      password: encrypt_password(user_params[:password])
    }
    user_ref = FirestoreDB.col('users').add(user_data)
    user = user_ref.get
    render json: user.data.merge(id: user.document_id), status: :created
  end

  def update
    user_ref = FirestoreDB.col('users').doc(params[:id])
    user = user_ref.get
  
    if user.exists?
      user_data = user.data.dup  # Crear una copia mutable del hash
      user_params.each do |key, value|
        if user_data.key?(key.to_sym)
          if key.to_sym == :password
            user_data[key.to_sym] = encrypt_password(value)
          else
            user_data[key.to_sym] = value
          end
        end
      end
  
      user_ref.set(user_data)
      updated_user = user_ref.get
      render json: updated_user.data.merge(id: updated_user.document_id)
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  def destroy
    user_ref = FirestoreDB.col('users').doc(params[:id])
    user = user_ref.get
    if user.exists?
      user_ref.delete
      head :no_content
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  def create_user(user_params)
    user_data = {
      email: user_params[:email],
      full_name: user_params[:full_name],
      role: user_params[:role],
      campus: user_params[:campus],
      password: encrypt_password(user_params[:password])
    }
    user_ref = FirestoreDB.col('users').add(user_data)
    user = user_ref.get
    user.data.merge(id: user.document_id)
  end
  
  def authenticate
    email = params[:email]
    password = params[:password]

    user_query = FirestoreDB.col('users').where('email', '==', email).limit(1).get
    user = user_query.first

    if user.present? && password_match?(user.data[:password], password)
      render json: { message: 'Authentication successful', user_id: user.document_id }
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :full_name, :role, :campus, :password)
  end

  def encrypt_password(password)
    BCrypt::Password.create(password)
  end

  def password_match?(encrypted_password, plain_password)
    BCrypt::Password.new(encrypted_password) == plain_password
  end
end