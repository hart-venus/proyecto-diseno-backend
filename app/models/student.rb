
class Student < ApplicationRecord
    enum campus: { CA: 0, SJ: 1, AL: 2, LI: 3, SC: 4 }
  
    # Validaciones
    validates :student_id, presence: true, uniqueness: true, format: { with: /\A\d{8}\z/, message: "must be 8 digits" }
    validates :full_name, presence: true, format: { with: /\A[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+\s[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+\s[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(\s[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)?\z/, message: "must be in the format 'Apellido1 Apellido2 Nombre [Nombre Adicional]'" }
    validates :email, presence: true, uniqueness: true, format: { with: /\A[\w+\-.]+@estudiantec\.cr\z/i, message: "must be in the format '@estudiantec.cr'" }
    validates :phone, presence: true, format: { with: /\A\d{8}\z/, message: "must be 8 digits" }
    validates :campus, presence: true

    # Método para obtener el correo electrónico institucional del estudiante
    def institutional_email
        "#{student_id}@estudiantec.cr"
    end

  end