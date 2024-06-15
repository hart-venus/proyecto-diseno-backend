# app/models/student_inbox.rb
class StudentInbox
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :id, :student_id, :messages

  validates :student_id, presence: true

  def self.find_or_create_by_student_id(student_id)
    inbox = find_by_student_id(student_id)
    return inbox if inbox

    new_inbox = new(student_id: student_id)
    new_inbox.save
    new_inbox
  end

  def self.find_by_student_id(student_id)
    doc_ref = FirestoreDB.col('student_inboxes').where('student_id', '==', student_id).limit(1).get
    doc = doc_ref.first

    if doc
      data = doc.data.dup
      data['id'] = doc.document_id
      new(data)
    else
      nil
    end
  end

  def initialize(attributes = {})
    @id = attributes[:id]
    @student_id = attributes[:student_id]
    @messages = attributes[:messages] || []
  end

  def save
    if valid?
      data = {
        student_id: student_id,
        messages: messages
      }

      if id.present?
        FirestoreDB.col('student_inboxes').doc(id).set(data)
      else
        doc_ref = FirestoreDB.col('student_inboxes').add(data)
        self.id = doc_ref.document_id
      end

      true
    else
      false
    end
  end

  def add_message(message_data)
    messages << message_data
    save
  end
end