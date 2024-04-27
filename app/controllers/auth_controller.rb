# app/controllers/auth_controller.rb
class AuthController < ApplicationController
    protect_from_forgery with: :null_session # como es API no necesitamos protección CSRF
    def signup
        user = User.new(user_params)
        # si ya existe un usuario con el mismo correo, devolver un error
        if FirestoreDB.col('users').where('correo', '==', user.correo).get.any?
            render json: { errors: ['User already exists'] }, status: :conflict
            return
        end

        if user.valid?
            hashed_password = BCrypt::Password.create(user.password)
            user_data = {
                nombre_completo: user.nombre_completo,
                correo: user.correo,
                celular: user.celular,
                campus: user.campus,
                tipo: user.tipo,
                password: hashed_password
            }
            
            user_ref = FirestoreDB.col('users').add(user_data)
            user_id = user_ref.document_id
            token = JWT.encode({ user_id: user_id }, 'secret123', 'HS256')
            render json: { token: token }, status: :created
        else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def login
        puts "Correo recibido: #{params[:correo]}"
        puts "Contraseña recibida: #{params[:password]}"

        user_query = FirestoreDB.col('users').where('correo', '==', params[:correo])
        puts "Query de usuario: #{user_query.inspect}"

        user = user_query.get.first
        puts "Usuario encontrado: #{user.inspect}"

        if user
            puts "ID del documento del usuario: #{user.document_id}"
            puts "Contraseña almacenada: #{user[:password]}"

            if BCrypt::Password.new(user[:password]) == params[:password]
                token = JWT.encode({ user_id: user.document_id }, ENV['JWT_SECRET'], 'HS256')
                render json: { token: token }
            else
                puts "La contraseña no coincide"
                render json: { message: 'Invalid email or password' }, status: :unauthorized
            end
        else
            puts "No se encontró el usuario"
            render json: { message: 'Invalid email or password' }, status: :unauthorized
        end
    end

    private

    def user_params
        params.require(:user).permit(:nombre_completo, :correo, :celular, :campus, :tipo, :password)
    end
end
