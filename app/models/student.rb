
class Student
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks
  include Constants

  attr_accessor :carne, :last_name1, :last_name2, :name1, :name2, :email, :phone, :campus

  validates :carne, presence: true
  validates :last_name1, :last_name2, :name1, presence: true
  validates :email, presence: true, format: { with: /\A[\w+\-.]+@(estudiantec\.cr|itcr\.ac\.cr)\z/i, message: 'debe ser una dirección de correo electrónico válida de @estudiantec.cr o @itcr.ac.cr' }
  validates :phone, presence: true
  validates :campus, inclusion: { in: Constants::CAMPUSES.values, message: 'debe ser un campus válido' }

  def initialize(attributes = {})
    @carne = attributes[:carne]
    @last_name1 = attributes[:last_name1]
    @last_name2 = attributes[:last_name2]
    @name1 = attributes[:name1]
    @name2 = attributes[:name2]
    @email = attributes[:email]
    @phone = attributes[:phone]
    @campus = attributes[:campus]
    # parse carne and phone number to int if exists
    @carne = @carne ? @carne.to_i.to_s : nil
    @phone = @phone ? @phone.to_i.to_s : nil
  end

  def full_name
    "#{@last_name1} #{@last_name2} #{@name1} #{@name2}".strip
  end

  def save
    if valid?
      student_data = {
        carne: @carne,
        last_name1: @last_name1,
        last_name2: @last_name2,
        name1: @name1,
        name2: @name2 || '',
        email: @email,
        phone: @phone,
        campus: @campus
      }
      student_ref = FirestoreDB.col('students').doc(@carne)
      student_ref.set(student_data)
      student_ref # truthy
    else
      false
    end
  end

  def self.find(carne)
    student_doc = FirestoreDB.col('students').doc(carne).get
    if student_doc.exists?
      student_data = student_doc.data
      new(student_data)
    else
      nil
    end
  end

  def self.find_by_campus(campus)
    students = FirestoreDB.col('students').where('campus', '==', campus).get
    students.map { |student_doc| new(student_doc.data) }
  end

  def update(attributes)
    attributes = attributes.dup # Crear una copia del hash para evitar modificar el original

    @last_name1 = attributes.delete(:last_name1) || @last_name1
    @last_name2 = attributes.delete(:last_name2) || @last_name2
    @name1 = attributes.delete(:name1) || @name1
    @name2 = attributes.delete(:name2) || @name2
    @email = attributes.delete(:email) || @email
    @phone = attributes.delete(:phone) || @phone
    @campus = attributes.delete(:campus) || @campus

    if valid?
      student_data = {
        last_name1: @last_name1,
        last_name2: @last_name2,
        name1: @name1,
        name2: @name2,
        email: @email,
        phone: @phone,
        campus: @campus
      }
      student_ref = FirestoreDB.col('students').doc(@carne)
      student_ref.update(student_data)
      student_ref # truthy
    else
      false
    end
  end

  def destroy
    FirestoreDB.col('students').doc(@carne).delete
    @carne = nil
    @last_name1 = nil
    @last_name2 = nil
    @name1 = nil
    @name2 = nil
    @email = nil
    @phone = nil
    @campus = nil
    true
  end

  def self.find_by_user_id(user_id)
    student_doc = FirestoreDB.col('students').where('user_id', '==', user_id).limit(1).get.first
    if student_doc
      student_data = student_doc.data
      new(student_data)
    else
      nil
    end
  end
end
