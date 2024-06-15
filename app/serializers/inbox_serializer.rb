class InboxSerializer < ActiveModel::Serializer
    attributes :id, :student_id
    has_many :messages
  end