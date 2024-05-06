class User
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  attr_accessor :id, :email, :full_name, :role, :campus, :password

  ROLES = { professor: 'professor', admin: 'admin' }
  CAMPUSES = { CA: 'CA', SJ: 'SJ', AL: 'AL', LI: 'LI', SC: 'SC' }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, :role, :campus, :password, presence: true
  validates :password, length: { minimum: 8 }
  validates :role, inclusion: { in: ROLES.values }
  validates :campus, inclusion: { in: CAMPUSES.values }

  def initialize(attributes = {})
    @id = attributes[:id] || generate_unique_id
    @email = attributes[:email]
    @full_name = attributes[:full_name]
    @role = attributes[:role]
    @campus = attributes[:campus]
    @password = attributes[:password]
  end

  def professor?
    role == ROLES[:professor]
  end

  def admin?
    role == ROLES[:admin]
  end

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

  def generate_unique_id
    FirestoreDB.col('users').doc.document_id
  end
  
end