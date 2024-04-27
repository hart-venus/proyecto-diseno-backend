# app/controllers/users_controller.rb
class UsersController < ApplicationController
    protect_from_forgery with: :null_session
    before_action :authenticate_request!, only: [:show, :index, :update]

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

    def update
        target_user_id = params[:id]
        target_user_doc = FirestoreDB.doc("users/#{target_user_id}")

        if can_edit_user?(target_user_doc)
            user_params = params.require(:user).permit(:nombre_completo, :correo, :celular, :campus, :active, :identificador)
            clean_params = {
                nombre_completo: user_params[:nombre_completo],
                correo: user_params[:correo],
                celular: user_params[:celular],
                campus: user_params[:campus],
                active: user_params[:active],
                identificador: user_params[:identificador]
            }
            # remove empty fields
            clean_params.delete_if { |k, v| v.nil? }
            
            target_user_doc.set(clean_params, merge: true)
            render json: { message: 'User updated successfully' }
        else
            render json: { error: 'Not authorized to edit this user' }, status: :forbidden
        end
    end

    private

    def can_edit_user?(target_user)
        document_id = @current_user[:document_id]
        target_tipo = target_user.get[:tipo]
        return true if document_id == target_user.document_id # Users can always edit themselves

        case current_user[:tipo]
        when 'AsistenteAdmin'
            ['Profesor', 'ProfesorCoordinador', 'Estudiante'].include?(target_tipo)
        when 'Profesor', 'ProfesorCoordinador'
            target_tipo == 'Estudiante'
        else
            false
        end
    end
end
