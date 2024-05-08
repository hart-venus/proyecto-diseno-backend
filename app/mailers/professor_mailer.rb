class ProfessorMailer < ApplicationMailer
    def welcome_email(professor, user_email, user_password)
      @professor = professor
      @user_email = user_email
      @user_password = user_password
  
      mail(to: professor.email, subject: 'Welcome to the System')
    end
    def credentials_email(professor_data, user_email, user_password)
      @professor_data = professor_data
      @user_email = user_email
      @user_password = user_password
      mail(to: professor_data[:email], subject: 'Recordatorio de Credenciales')
    end
  end