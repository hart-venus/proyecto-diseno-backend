class Activity
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :id, :work_plan_id, :week, :activity_type, :name, :date, :time, :responsible_ids,
                :announcement_days, :reminder_days, :is_remote, :meeting_link, :poster_url, :status,
                :cancel_reason, :evidences

  validates :work_plan_id, :week, :activity_type, :name, :date, :time, :responsible_ids,
            :announcement_days, :reminder_days, :is_remote, :status, presence: true
  validates :week, inclusion: { in: 1..16 }
  validates :status, inclusion: { in: ['PLANEADA', 'NOTIFICADA', 'REALIZADA', 'CANCELADA'] }

  def self.create(attributes)
    activity = new(attributes)
    if activity.valid?
      activity_ref = FirestoreDB.col('activities').add(activity.attributes)
      activity.id = activity_ref.document_id
      activity
    else
      nil
    end
  end

  def self.find(id)
    doc = FirestoreDB.col('activities').doc(id).get
    if doc.exists?
      data = doc.data
      data['id'] = doc.document_id
      new(data)
    else
      nil
    end
  end

  def self.find_by_work_plan(work_plan_id)
    activities = []
    FirestoreDB.col('activities').where('work_plan_id', '==', work_plan_id).get do |activity_doc|
      data = activity_doc.data
      data['id'] = activity_doc.document_id
      activities << new(data)
    end
    activities
  end

  def update(attributes)
    merge_attributes(attributes)
    if valid?
      FirestoreDB.col('activities').doc(id).update(attributes)
      true
    else
      false
    end
  end

  def add_evidence(evidence_url)
    self.evidences ||= []
    self.evidences << evidence_url
    FirestoreDB.col('activities').doc(id).update(evidences: evidences)
  end

  def mark_as_done
    self.status = 'REALIZADA'
    FirestoreDB.col('activities').doc(id).update(status: 'DONE')
  end

  def cancel(reason)
    self.status = 'CANCELADA'
    self.cancel_reason = reason
    FirestoreDB.col('activities').doc(id).update(status: 'CANCELED', cancel_reason: reason)
  end

  def attributes
    {
      id: id,
      work_plan_id: work_plan_id,
      week: week,
      activity_type: activity_type,
      name: name,
      date: date,
      time: time,
      responsible_ids: responsible_ids,
      announcement_days: announcement_days,
      reminder_days: reminder_days,
      is_remote: is_remote,
      meeting_link: meeting_link,
      poster_url: poster_url,
      status: status,
      cancel_reason: cancel_reason,
      evidences: evidences
    }
  end
end