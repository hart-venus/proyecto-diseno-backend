class User < ApplicationRecord
    has_secure_password
  
    enum role: { professor: 0, admin: 1 }
    enum campus: { CA: 0, SJ: 1, AL: 2, LI: 3, SC: 4 }
  
    # Validaciones
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true, length: { minimum: 6 }
    validates :role, presence: true
    validates :full_name, presence: true
    validates :campus, presence: true

    #Método para obtener el nombre completo del usuario
    def full_name
      "#{first_name} #{last_name}"
    end
  
    # Método para verificar si el usuario es un profesor
    def professor?
      role == 'professor'
    end
  
    # Método para verificar si el usuario es un administrador
    def admin?
      role == 'admin'
    end

  end
