class User < ApplicationRecord
  has_one :professor
  has_one :administrative_assistant

  enum role: { professor: 0, admin: 1 }
  enum campus: { CA: 0, SJ: 1, AL: 2, LI: 3, SC: 4 }

  validates :email, presence: true, uniqueness: true
  validates :full_name, :role, :campus, :password, presence: true
  validates :password, length: { minimum: 8 }

  # Método para verificar si el usuario es un profesor
  def professor?
    role == 'professor'
  end

  # Método para verificar si el usuario es un administrador
  def admin?
    role == 'admin'
  end

end
