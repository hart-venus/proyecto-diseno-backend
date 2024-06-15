class StudentInbox
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :student_carne, :notifications_list

  validates :student_carne, presence: true

  def self.find_by_student(student_carne)
    inbox_doc = FirestoreDB.col('student_inboxes').doc(student_carne).get
    if inbox_doc.exists?
      notifications = inbox_doc.data[:notifications].map { |notification_data| Notification.new(notification_data).attributes }
      new(student_carne: student_carne, notifications_list: notifications)
    else
      nil
    end
  end

  def notifications
    @notifications_list || []
  end

  def add_notification(notification)
    @notifications_list ||= []
    @notifications_list << notification.attributes
    update_notifications_in_firestore
  end

  def create_notification(attributes)
    attributes[:recipient_id] = student_carne
    notification = Notification.create(attributes)
    add_notification(notification) if notification.present?
    notification
  end

  def save
    if valid?
      inbox_ref = FirestoreDB.col('student_inboxes').doc(student_carne)
      inbox_ref.set({ notifications: [] })
      true
    else
      false
    end
  end

  def update(id, attributes)
    # change the attributes in the attributes hash (the rest of the hash should be the same)
    for i in 0..@notifications_list.length do
      if @notifications_list[i][:id] == id
        @notifications_list[i].merge!(attributes)
        update_notifications_in_firestore
        return @notifications_list[i]
      end
    end
    nil
  end

  def delete(id)
    for i in 0..@notifications_list.length do
      if @notifications_list[i][:id] == id
        @notifications_list.delete_at(i)
        update_notifications_in_firestore
        return true
      end
    end
    false
  end

  private

  def update_notifications_in_firestore
    inbox_ref = FirestoreDB.col('student_inboxes').doc(student_carne)
    inbox_ref.update({ notifications: notifications })
  end
end
