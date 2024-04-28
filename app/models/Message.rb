class Message 
    include ActiveModel::Model
    attr_accessor :sender, :activity_ref, :date, :content, :active

    validates :activity_ref, :date, :content, presence: true

    def initialize(attributes={})
        super
        @active = true
    end
end