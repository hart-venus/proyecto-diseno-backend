class ProfessorMailer < ApplicationMailer
    def welcome_email(professor, user_email, user_password)
      @professor = professor
      @user_email = user_email
      @user_password = user_password
  
      mail(to: professor.email, subject: 'Welcome to the System')
    end
  end