
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
      FirestoreDB.col('students').doc(@carne).set(student_data)
      true
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

  def update(attributes)
    if valid?
      student_data = {
        full_name: attributes[:full_name] || @full_name,
        email: attributes[:email] || @email,
        phone: attributes[:phone] || @phone,
        campus: attributes[:campus] || @campus
      }
      FirestoreDB.col('students').doc(@carne).update(student_data)
      true
    else
      false
    end
  end

  def destroy
    FirestoreDB.col('students').doc(@carne).delete
    true
  end
end