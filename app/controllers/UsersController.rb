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
    user = User.new(user_params)
    if user.valid?
      created_user = create_user_in_firestore(user)
      render json: created_user, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create_user(user_params)
    user = User.new(user_params)
    if user.valid?
      created_user = create_user_in_firestore(user)
      created_user
    else
      raise "Invalid user data: #{user.errors.full_messages.join(', ')}"
    end
  end

  def update
    user_ref = FirestoreDB.col('users').doc(params[:id])
    user = user_ref.get

    if user.exists?
      user_data = user.data.dup

      if user_params[:password].present?
        user_data[:password] = encrypt_password(user_params[:password])
      end

      user_params.slice(:full_name, :role, :campus).each do |key, value|
        user_data[key] = value
      end

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

    user = FirestoreDB.col('users').where('email', '==', email).get.first

    if user.present? && password_match?(user.data[:password], password)
      if user.data[:role] != Constants::ROLES[:student]
          render json: { message: 'Authentication successful', user_id: user.document_id }
      else # devolver el student id del usuario si este es un estudiante
        student_ref = FirestoreDB.col('students').where('email', '==', email).get.first
        render json: { message: 'Authentication successful', student_id: student_ref.document_id, user_id: user.document_id }
      end
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def recover_password
    email = params[:email]

    user_doc = FirestoreDB.col('users').where('email', '==', email).get.first

    if user_doc.present?
      temporary_password = SecureRandom.base64(10)
      encrypted_password = encrypt_password(temporary_password)

      user_doc.ref.update({ password: encrypted_password })

      updated_user_data = user_doc.data.merge(id: user_doc.document_id)

      ProfessorMailer.password_recovery_email(updated_user_data, email, temporary_password).deliver_now

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

    users = FirestoreDB.collection("users").where("campus", "==", campus).get.to_a
    if users.empty?
      render json: { error: 'No users found for the specified campus' }, status: :not_found
    else
      render json: users.map { |user| user.data.merge(id: user.document_id) }
    end
  end

  def find_by_role
    role = params[:role]
    unless validate_role(role)
      return
    end

    users = FirestoreDB.collection("users").where('role', '==', role).get.to_a
    if users.empty?
      render json: { error: 'No users found for the specified role' }, status: :not_found
    else
      render json: users.map { |user| user.data.merge(id: user.document_id) }
    end
  end

  def find_by_email
    email = params[:email]
    unless validate_email(email)
      return
    end

    user = FirestoreDB.col('users').where('email', '==', email).get.first
    if user.present?
      render json: user.data.merge(id: user.document_id)
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :full_name, :role, :campus, :password)
  end

  def create_user_in_firestore(user)
    existing_user = FirestoreDB.col('users').where('email', '==', user.email).get.first
    if existing_user.present?
      raise "Email already exists"
    else
      user_data = {
        email: user.email,
        full_name: user.full_name,
        role: user.role,
        campus: user.campus,
        password: encrypt_password(user.password)
      }
      user_ref = FirestoreDB.col('users').add(user_data)
      user_doc = user_ref.get
      user_doc.data.merge(id: user_doc.document_id)
    end
  end

  def encrypt_password(password)
    BCrypt::Password.create(password)
  end

  def password_match?(encrypted_password, plain_password)
    BCrypt::Password.new(encrypted_password) == plain_password
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
