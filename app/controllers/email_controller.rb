class EmailController < ApplicationController
    skip_forgery_protection
    def send_email
      # Lógica para enviar el correo electrónico
      UserMailer.send_notification_email.deliver_now
  
      # Respuesta al cliente
      render json: { message: 'Correo electrónico enviado correctamente' }
    end
  end