
class Student
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
    include Constants
  
    attr_accessor :carne, :full_name, :email, :phone, :campus
  
    validates :carne, presence: true, format: { with: /\A\d{8}\z/, message: 'must be in the format YYYY-NNNN' }
    validates :full_name, presence: true, format: { with: /\A[A-Z][a-z]+ [A-Z][a-z]+ [A-Z][a-z]+(?: [A-Z][a-z]+)?\z/, message: 'must be in the format "Apellido1 Apellido2 Nombre [Nombre Adicional]"' }
    validates :email, presence: true, format: { with: /\A[\w+\-.]+@estudiantec\.cr\z/i, message: 'must be a valid @estudiantec.cr email address' }
    validates :phone, presence: true, format: { with: /\A\d{8}\z/, message: 'must be 8 digits' }
    validates :campus, inclusion: { in: Constants::CAMPUSES.values, message: 'must be a valid campus' }
  
    def initialize(attributes = {})
      @carne = attributes[:carne]
      @full_name = attributes[:full_name]
      @email = attributes[:email]
      @phone = attributes[:phone]
      @campus = attributes[:campus]
    end
  
    def save
      if valid?
        student_data = {
          carne: @carne,
          full_name: @full_name,
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