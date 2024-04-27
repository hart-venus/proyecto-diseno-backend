# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
    def authenticate_request!
        token = request.headers['Authorization']&.split(' ')&.last
        payload = JWT.decode(token, 'secret123', true, algorithm: 'HS256').first
        user_data = FirestoreDB.doc("users/#{payload['user_id']}").get
        # add document_id to the user object
        @current_user = {
            document_id: payload['user_id'],
            nombre_completo: user_data['nombre_completo'],
            correo: user_data['correo'],
            celular: user_data['celular'],
            campus: user_data['campus'],
            tipo: user_data['tipo'],
            identificador: user_data['identificador']
        }
    rescue JWT::VerificationError, JWT::DecodeError
        render json: { message: 'Invalid token' }, status: :unauthorized
    end
end
