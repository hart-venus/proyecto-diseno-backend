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
      data = doc.data.dup # Crear una copia mutable del hash
      data['id'] = doc.document_id
      new(data)
    else
      nil
    end
  end
 
  def self.find_by_work_plan(work_plan_id)
    activities = []
    FirestoreDB.col('activities').where('work_plan_id', '==', work_plan_id).get do |activity_doc|
      data = activity_doc.data.dup # Crear una copia mutable del hash
      data['id'] = activity_doc.document_id
      activities << new(data)
    end
    activities
  end
 
  def update(attributes)
    attrs = self.attributes.dup # Crear una copia mutable del hash de atributos
    attrs.merge!(attributes)
    if valid?
      FirestoreDB.col('activities').doc(id).update(attrs)
      true
    else
      false
    end
  end
 
  def add_evidence(evidence_url)
    attrs = self.attributes.dup # Crear una copia mutable del hash de atributos
    attrs['evidences'] ||= []
    attrs['evidences'] << evidence_url
    FirestoreDB.col('activities').doc(id).update(evidences: attrs['evidences'])
  end
 
  def self.notify(activity_id)
    activity_ref = FirestoreDB.col('activities').doc(activity_id)
    activity_doc = activity_ref.get
  
    if activity_doc.exists?
      activity_data = activity_doc.data.dup # Duplicar el hash
      activity_data['status'] = 'NOTIFICADA'
      activity_ref.update(status: 'NOTIFICADA')
      true
    else
      false
    end
  end
  
  def self.mark_as_done(activity_id, evidence_urls)
    activity_ref = FirestoreDB.col('activities').doc(activity_id)
    activity_doc = activity_ref.get
  
    if activity_doc.exists?
      activity_data = activity_doc.data.dup # Duplicar el hash
      activity_data['status'] = 'REALIZADA'
      activity_data['evidences'] = evidence_urls
      activity_ref.update(status: 'REALIZADA', evidences: evidence_urls)
      true
    else
      false
    end
  end
  
  def self.cancel(activity_id, reason)
    activity_ref = FirestoreDB.col('activities').doc(activity_id)
    activity_doc = activity_ref.get
  
    if activity_doc.exists?
      activity_data = activity_doc.data.dup # Duplicar el hash
      activity_data['status'] = 'CANCELADA'
      activity_data['cancel_reason'] = reason
      activity_ref.update(status: 'CANCELADA', cancel_reason: reason)
      true
    else
      false
    end
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