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
    existing_user = FirestoreDB.col('users').where('email', '==', user_params[:email]).get.first
    if existing_user.present?
      render json: { error: 'Email already exists' }, status: :unprocessable_entity
    else
      user = User.new(user_params)
      if user.valid?
        user_data = {
          email: user.email,
          full_name: user.full_name,
          role: user.role,
          campus: user.campus,
          password: encrypt_password(user.password)
        }
        user_ref = FirestoreDB.col('users').add(user_data)
        user_doc = user_ref.get
        render json: user_doc.data.merge(id: user_doc.document_id), status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def update
    user_ref = FirestoreDB.col('users').doc(params[:id])
    user = user_ref.get
  
    if user.exists?
      user_data = user.data.dup
      user_params.each do |key, value|
        if user_data.key?(key.to_sym)
          if key.to_sym == :password
            user_data[key.to_sym] = encrypt_password(value)
          elsif key.to_sym != :email
            user_data[key.to_sym] = value
          end
        end
      end
  
      # Verificar si el correo electrónico ya existe en otro usuario
      if user_params[:email].present? && user_params[:email] != user_data[:email]
        existing_user = FirestoreDB.col('users').where('email', '==', user_params[:email]).get.first
        if existing_user.present?
          render json: { error: 'Email already exists' }, status: :unprocessable_entity
          return
        else
          user_data[:email] = user_params[:email]
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

  def find_by_campus
    campus = params[:campus]
    campus_key = campus.to_sym
    if User::CAMPUSES.key?(campus_key)
      users = FirestoreDB.col('users').where('campus', '==', User::CAMPUSES[campus_key]).get
      render json: users.map { |user| user.data.merge(id: user.document_id) }
    else
      render json: { error: 'Invalid campus' }, status: :bad_request
    end
  end
  
  def find_by_role
    role = params[:role]
    users = FirestoreDB.col('users').where('role', '==', role).get
    render json: users.map { |user| user.data.merge(id: user.document_id) }
  end
  
  def find_by_email
    email = params[:email]
    user_query = FirestoreDB.col('users').where('email', '==', email).limit(1).get
    user = user_query.first
    if user.present?
      render json: user.data.merge(id: user.document_id)
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end


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