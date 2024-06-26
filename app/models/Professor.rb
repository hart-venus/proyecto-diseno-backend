class Professor
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks
  include Constants

  define_model_callbacks :create

  # Atributos de la clase Professor
  attr_accessor :id, :code, :full_name, :email, :office_phone, :cellphone, :photo_url, :status, :coordinator, :user_id, :campus

  # Constante para los estados posibles de un profesor
  STATUSES = { active: 'active', inactive: 'inactive' }

  # Validaciones para los atributos de Professor
  validates :code, presence: true
  validates :full_name, :email, :cellphone, :campus, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :office_phone, format: { with: /\A\d{4}-\d{4}(?:\[ext\.\d{4}\])?\z/i, message: 'must be in the format NNNN-NNNN[ext.NNNN]' }, allow_blank: true
  validates :cellphone, format: { with: /\A\d{8}\z/, message: 'must be 8 digits' }
  validates :photo_url, format: { with: URI::DEFAULT_PARSER.make_regexp, message: 'must be a valid URL' }, allow_blank: true
  validates :status, inclusion: { in: STATUSES.values }
  validates :campus, inclusion: { in: Constants::CAMPUSES.values }
  validates :coordinator, inclusion: { in: [true, false] }

  # Constructor de la clase Professor
  def initialize(attributes = {})
    attributes.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end
  end

  # Método para activar un profesor
  def activate
    self.status = 'active'
  end

  # Método para desactivar un profesor
  def deactivate
    self.status = 'inactive'
  end

  # Método para obtener los atributos del profesor como un hash
  def attributes
    {
      id: id,
      code: code,
      full_name: full_name,
      email: email,
      office_phone: office_phone,
      cellphone: cellphone,
      photo_url: photo_url,
      status: status,
      coordinator: coordinator,
      user_id: user_id,
      campus: campus
    }
  end
end