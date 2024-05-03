class Activity 
    include ActiveModel::Model 
    attr_accessor :indole, :estado, :semana, :nombre, :fecha, :responsables, :recordatorios, :presencial, :enlace, :plan_ref, :active

    INDOLE_TYPES = %w[Orientadora Motivacional Apoyadora Tecnica Recreacional].freeze
    ESTADO_TYPES = %w[Planeada Notificada Realizada Cancelada].freeze

    validates :indole, :semana, :nombre, :fecha, :presencial, :plan_ref, presence: true
    validates :indole, inclusion: { in: INDOLE_TYPES }
    validates :estado, inclusion: { in: ESTADO_TYPES }
    validates :presencial, inclusion: { in: [true, false] }

    def initialize(attributes={})
        super
        @estado = 'Planeada'
        @active = true
    end
end

class Activity < ApplicationRecord
    enum activity_type: { orientadora: 0, motivacional: 1, apoyo_estudiantil: 2, tecnica: 3, recreativa: 4 }
    enum modality: { presencial: 0, remota: 1 }
    enum status: { planeada: 0, notificada: 1, realizada: 2, cancelada: 3 }
  
    belongs_to :plan
    has_many :comments, dependent: :destroy
    has_many :evidences, dependent: :destroy
  
    validates :week_number, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 16 }
    validates :activity_type, presence: true
    validates :name, presence: true
    validates :start_date, presence: true
    validates :end_date, presence: true
    validates :advance_notice_days, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :reminder_days, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :modality, presence: true
    validates :meeting_link, presence: true, if: :remota?
    validates :poster_url, presence: true, format: { with: URI.regexp, message: "must be a valid URL" }
    validates :status, presence: true
  
    validate :end_date_after_start_date
    validate :reminder_days_within_range
  
    after_create :set_publication_date
    after_update :update_publication_date, if: :advance_notice_days_changed?
    after_update :set_reminder_dates, if: :reminder_days_changed?
  
    def professors
      Professor.where(id: professor_ids)
    end
  
    def professor_ids
      data[:professor_ids] || []
    end
  
    def professor_ids=(ids)
      data[:professor_ids] = ids
    end
  
    private
  
    def end_date_after_start_date
      if end_date.present? && start_date.present? && end_date < start_date
        errors.add(:end_date, "must be after the start date")
      end
    end
  
    def reminder_days_within_range
      if reminder_days.present? && advance_notice_days.present? && reminder_days > (start_date - Date.current).to_i
        errors.add(:reminder_days, "must be within the range between current date and activity start date")
      end
    end
  
    def set_publication_date
      self.publication_date = start_date - advance_notice_days.days
      save
    end
  
    def update_publication_date
      set_publication_date
    end
  
    def set_reminder_dates
      reminder_dates = []
      reminder_days.times do |i|
        reminder_dates << start_date - (i + 1).days
      end
      self.reminder_dates = reminder_dates
      save
    end
  end