class Inbox
    attr_accessor :id, :student_id
  
    def initialize(attributes = {})
      @id = attributes[:id]
      @student_id = attributes[:student_id]
    end
  
    def messages
      Message.where(student_id: @student_id)
    end
  end