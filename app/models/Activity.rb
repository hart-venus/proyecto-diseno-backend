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