class Notification
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :id, :sender, :recipient_id, :content, :status, :created_at

    validates :sender, :recipient_id, :content, presence: true
    validates :status, inclusion: { in: ['UNREAD', 'READ'] }

    def self.create(attributes)
      notification = new(attributes)
      notification.status = 'UNREAD'
      if notification.valid?
        notification.created_at = Time.now
        # generate uuid
        notification.id = SecureRandom.uuid
        notification.status = 'UNREAD'
        notification
      else
        nil
      end
    end

    def self.find(id)
      doc = FirestoreDB.col('notifications').doc(id).get
      if doc.exists?
        data = doc.data.dup
        data['id'] = doc.document_id
        new(data)
      else
        nil
      end
    end

    def self.find_by_recipient(recipient_id)
      notifications = []
      FirestoreDB.col('notifications').where('recipient_id', '==', recipient_id).order_by('created_at', 'desc').get do |notification_doc|
        data = notification_doc.data.dup
        data['id'] = notification_doc.document_id
        notifications << new(data)
      end
      notifications
    end

    def mark_as_read
      update(status: 'READ')
    end

    def update(attributes)
      attrs = self.attributes.dup
      attrs.merge!(attributes)
      if valid?
        FirestoreDB.col('notifications').doc(id).update(attrs)
        true
      else
        false
      end
    end

    def attributes
      {
        id: id,
        sender: sender,
        recipient_id: recipient_id,
        content: content,
        status: status,
        created_at: created_at
      }
    end
  end
