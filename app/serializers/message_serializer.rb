class MessageSerializer < ActiveModel::Serializer
    attributes :id, :subject, :content, :read, :created_at
  end