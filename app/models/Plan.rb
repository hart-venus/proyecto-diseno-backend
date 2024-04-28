class Plan 
    include ActiveModel::Model 
    attr_accessor :nombre, :active, :sede 

    CAMPUS_TYPES = %w[CA SJ LI AL SC].freeze

    validates :nombre, :sede, presence: true
    validates :sede, inclusion: { in: CAMPUS_TYPES }   

    def initialize(attributes={})
        super
        @active = true
    end
end