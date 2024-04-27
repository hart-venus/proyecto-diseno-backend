# app/controllers/test_controller.rb
class TestController < ApplicationController
    protect_from_forgery with: :null_session # como es API no necesitamos protección CSRF
    before_action :authenticate_request!, only: [:protected]

    def protected
        render json: { message: "Hello, #{@current_user[:nombre_completo]}! This is a protected route." }
    end
end
