class Plan < ApplicationRecord
    enum status: { active: 0, inactive: 1 }
    enum semester: { first: 0, second: 1 }
  
    # Validaciones
    validates :name, presence: true
    validates :start_date, presence: true
    validates :end_date, presence: true
    validates :year, presence: true
    validates :semester, presence: true
    validates :coordinator_id, presence: true
    validate :end_date_after_start_date
    validate :duration_is_16_weeks
  
    # Asociaciones
    belongs_to :coordinator, class_name: 'Professor'
    has_many :plan_professors
    has_many :professors, through: :plan_professors
    has_many :activities, dependent: :destroy
  
    # Registro de creación
    after_create :record_creation
  
    private
  
    def end_date_after_start_date
      if end_date.present? && start_date.present? && end_date < start_date
        errors.add(:end_date, "must be after the start date")
      end
    end
  
    def duration_is_16_weeks
      if start_date.present? && end_date.present?
        duration_weeks = (end_date - start_date).to_i / 7
        if duration_weeks != 16
          errors.add(:end_date, "must be 16 weeks after the start date")
        end
      end
    end
  
    def record_creation
        # Crear un registro de auditoría
        audit = PlanAudit.new(
          plan_id: id,
          user_id: coordinator_id,
          action: 'create'
        )
        audit.save
      end
    
      # Método para marcar un plan como inactivo
      def deactivate
        update(status: :inactive)
      end
    
      # Método para obtener el año y semestre del plan
      def semester_info
        "#{year}-#{semester == 'first' ? 'I' : 'II'}"
      end
    
      # Método para obtener la lista de profesores asociados al plan
      def professor_list
        professors.pluck(:full_name).join(', ')
      end
    
      # Método para verificar si el plan está activo
      def active?
        status == 'active'
      end
    end
  end