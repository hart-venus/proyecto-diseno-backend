# app/controllers/users_controller.rb
class UsersController < ApplicationController
    protect_from_forgery with: :null_session
    before_action :authenticate_request!, only: [:show, :index]

    def show
        user_id = params[:id]
        user_doc = FirestoreDB.doc("users/#{user_id}").get

        if user_doc['active']
            user_data = user_doc
            user_obj = {
                id: user_id,
                nombre_completo: user_data['nombre_completo'],
                correo: user_data['correo'],
                celular: user_data['celular'],
                campus: user_data['campus'],
                tipo: user_data['tipo'],
                identificador: user_data['identificador']
            }
            render json: user_obj
        else
        render json: { error: 'User not found' }, status: :not_found
        end
    end

    def index
        users_ref = FirestoreDB.col('users')
        users = users_ref.where('active', '==', true).get
        # translate each user into a hash of useful fields
        users_data = users.map do |user|
            user_data = user 
            user_obj = {
                id: user.document_id,
                nombre_completo: user_data['nombre_completo'],
                correo: user_data['correo'],
                celular: user_data['celular'],
                campus: user_data['campus'],
                tipo: user_data['tipo'],
                identificador: user_data['identificador']
            }
            user_obj 
        end
        render json: users_data
    end
end
