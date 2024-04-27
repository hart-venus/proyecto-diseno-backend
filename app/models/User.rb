
class User
    include ActiveModel::Model
    attr_accessor :nombre_completo, :correo, :celular, :campus, :tipo, :password

    CAMPUS_TYPES = %w[CA SJ LI AL SC].freeze
    USER_TYPES = %w[AsistenteAdmin Estudiante Profesor ProfesorGuia].freeze

    validates :nombre_completo, :correo, :celular, :campus, :tipo, :password, presence: true
    validates :correo, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }
    validates :campus, inclusion: { in: CAMPUS_TYPES }
    validates :tipo, inclusion: { in: USER_TYPES }
end