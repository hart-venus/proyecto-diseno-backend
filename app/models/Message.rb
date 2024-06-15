class Message
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
  
    attr_accessor :id, :student_id, :subject, :content, :read, :created_at
  
    validates :student_id, :subject, :content, presence: true
  
    def initialize(attributes = {})
      @id = attributes[:id] || generate_id
      @student_id = attributes[:student_id]
      @subject = attributes[:subject]
      @content = attributes[:content]
      @read = attributes[:read] || false
      @created_at = attributes[:created_at] || Time.now
    end
  
    def self.find(id)
      message_doc = FirestoreDB.col('messages').doc(id).get
      if message_doc.exists?
        message_data = message_doc.data
        new(message_data.merge(id: message_doc.document_id))
      else
        nil
      end
    end
  
    def save
      if valid?
        message_data = {
          student_id: @student_id,
          subject: @subject,
          content: @content,
          read: @read,
          created_at: @created_at
        }
        FirestoreDB.col('messages').doc(@id).set(message_data)
        true
      else
        false
      end
    end
  
    private
  
    def generate_id
      FirestoreDB.col('messages').doc.document_id
    end
  end