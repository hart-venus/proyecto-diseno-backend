class Professor < User
    # Validaciones
    validates :code, presence: true, uniqueness: true, format: { with: /\A[A-Z]{2}-\d{2}\z/, message: "Debe estar en formato XX-NN" }
    validates :office_phone, presence: true, format: { with: /\A\d{4}-\d{4}( ext \d{4})?\z/, message: "Debe estar en formato NNNN-NNNN or NNNN-NNNN ext NNNN" }
    validates :mobile_phone, presence: true, format: { with: /\A\d{8}\z/, message: "must be 8 digits" }
    validates :photo_url, format: { with: URI.regexp, message: "must be a valid URL" }, allow_blank: true
  
    # Asociaciones
    has_many :plan_professors
    has_many :plans, through: :plan_professors
    has_many :activity_professors
    has_many :activities, through: :activity_professors
  
    # Callback para generar contraseña temporal
    before_create :generate_temporary_password
    after_create :send_temporary_password
  
    private
  
    def generate_temporary_password
      self.password = SecureRandom.hex(8)
      self.password_confirmation = password
    end
  
    def send_temporary_password
      ProfessorMailer.temporary_password(self).deliver_now
    end

    # Método para verificar si el profesor es coordinador de algún plan
    def coordinator?
        plans.where(coordinator_id: id).exists?
    end

    # Método para obtener la lista de planes en los que el profesor está involucrado
    def plan_list
        plans.pluck(:name).join(', ')
    end

  end