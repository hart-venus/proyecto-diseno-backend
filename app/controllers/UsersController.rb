class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :deactivate]

  def index
    @users = FirestoreDB.col('users').get.map { |doc| doc.data }  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.valid?
      hashed_password = BCrypt::Password.create(@user.password)
      user_data = {
        email: @user.email,
        full_name: @user.full_name,
        role: @user.role,
        campus: @user.campus,
        password: hashed_password,
        active: true
      }

      user_ref = FirestoreDB.col('users').add(user_data)
      user_id = user_ref.document_id

      redirect_to user_path(user_id), notice: 'User created successfully.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      user_data = {
        email: @user.email,
        full_name: @user.full_name,
        role: @user.role,
        campus: @user.campus
      }

      if params[:user][:password].present?
        hashed_password = BCrypt::Password.create(params[:user][:password])
        user_data[:password] = hashed_password
      end

      FirestoreDB.col('users').doc(@user.id).set(user_data, merge: true)

      redirect_to user_path(@user.id), notice: 'User updated successfully.'
    else
      render :edit
    end
  end

  def deactivate
    FirestoreDB.col('users').doc(@user.id).update({ active: false })

    redirect_to users_path, notice: 'User deactivated successfully.'
  end

  def activate
    user_id = params[:user_id]
    FirestoreDB.col('users').doc(user_id).update({ active: true })

    redirect_to users_path, notice: 'User activated successfully.'
  end

  def find_by_email
    email = params[:email]
    user_data = FirestoreDB.col('users').where('email', '==', email).get.first&.data

    if user_data
      user = User.new(user_data)
      user.id = user_data[:id]
      render json: { user: user }, status: :ok
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  def find_by_id
    user_id = params[:user_id]
    user_data = FirestoreDB.col('users').doc(user_id).get.data

    if user_data
      user = User.new(user_data)
      user.id = user_id
      render json: { user: user }, status: :ok
    else
      render json: { error: 'User not found' }, status: :not    end
  end

  private

  def set_user
    user_data = FirestoreDB.col('users').doc(params[:id]).get.data
    @user = User.new(user_data)
    @user.id = params[:id]
  end

  def user_params
    params.require(:user).permit(:email, :full_name, :role, :campus, :password)
  end
end