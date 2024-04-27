# app/controllers/users_controller.rb
class UsersController < ApplicationController
    protect_from_forgery with: :null
    before_action :authenticate_request!, only: [:show, :index]

    def show
        user_id = params[:id]
        user_doc = FirestoreDB.doc("users/#{user_id}").get
        # quitamos el password del usuario
        user_doc.data.delete(:password)

        if user_doc.exists?
        user_data = user_doc.data
        render json: { user: user_data }, status: :ok
        else
        render json: { error: 'User not found' }, status: :not_found
        end
    end

    def index
        users = FirestoreDB.col('users').get
        # quitamos el password de los usuarios
        users.each { |user_doc| user_doc.data.delete(:password) }
        user_data = users.map { |user_doc| user_doc.data }
        render json: { users: user_data }, status: :ok
    end
end
