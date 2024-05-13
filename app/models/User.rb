class User
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks
  include Constants

  # Atributos de la clase User
  attr_accessor :id, :email, :full_name, :role, :campus, :password

  # Validaciones para los atributos de User
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, :role, :campus, :password, presence: true
  validates :password, length: { minimum: 8 }
  validates :role, inclusion: { in: Constants::ROLES.values }
  validates :campus, inclusion: { in: Constants::CAMPUSES.values }

  # Constructor de la clase User
  def initialize(attributes = {})
    @id = attributes[:id] || generate_unique_id
    @email = attributes[:email]
    @full_name = attributes[:full_name]
    @role = attributes[:role]
    @campus = attributes[:campus]
    @password = attributes[:password]
  end

  def self.find_by_id(user_id)
    user_doc = FirestoreDB.col('users').doc(user_id).get
    if user_doc.exists?
      user_data = user_doc.data
      new(user_data.merge(id: user_doc.document_id))
    else
      nil
    end
  end

  # Método para verificar si el usuario es un profesor
  def professor?
    role == Constants::ROLES[:professor]
  end

  # Método para verificar si el usuario es un administrador
  def admin?
    role == Constants::ROLES[:admin]
  end

  # Método para obtener los atributos del usuario como un hash
  def attributes
    {
      id: id,
      email: email,
      full_name: full_name,
      role: role,
      campus: campus,
      password: password
    }
  end

  private

  # Método para generar un ID único para el usuario
  def generate_unique_id
    FirestoreDB.col('users').doc.document_id
  end
end