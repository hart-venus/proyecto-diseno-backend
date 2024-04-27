# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
    def authenticate_request!
        token = request.headers['Authorization']&.split(' ')&.last
        payload = JWT.decode(token, 'secret123', true, algorithm: 'HS256').first
        @current_user = FirestoreDB.doc("users/#{payload['user_id']}").get.data
    rescue JWT::VerificationError, JWT::DecodeError
        render json: { message: 'Invalid token' }, status: :unauthorized
    end
end
