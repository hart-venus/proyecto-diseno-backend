class Activity
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :id, :work_plan_id, :week, :activity_type, :name, :date, :time, :responsible_ids,
                :announcement_days, :reminder_days, :is_remote, :meeting_link, :poster_url,
                :status, :cancel_reason, :evidences, :notification_date, :publication_date

  validates :work_plan_id, :week, :activity_type, :name, :date, :time, :responsible_ids,
            :announcement_days, :reminder_days, :is_remote, :status, presence: true
  validates :week, inclusion: { in: 1..16 }
  validates :status, inclusion: { in: ['PLANEADA', 'NOTIFICADA', 'REALIZADA', 'CANCELADA'] }

  def self.create(attributes)
    activity = new(attributes)
    if activity.valid?
      activity.calculate_dates
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
      calculate_dates
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

  # Acepta un visitor para la actividad y la fecha del sistema global
  def accept(visitor, global_system_date)
    visitor.visit(self, global_system_date)
  end

  # Regresa un arreglo con las fechas de notificación de la actividad
  def reminder_dates
    return [] unless publication_date && reminder_days

    # Regresa un arreglo con las fechas de notificación de la actividad
    # a partir de la fecha de publicación y la cantidad de días de anticipación
    (1..reminder_days).map { |days| publication_date + days }

  end

  # Cancela la actividad y notifica a los responsables
  def cancel(reason)
    update(status: 'CANCELADA', cancel_reason: reason)
    NotificationCenter.notify(self, 'CANCELLATION', "Activity canceled: #{name}. Reason: #{reason}")
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
      evidences: evidences,
      notification_date: notification_date,
      publication_date: publication_date
    }
  end

  def calculate_dates
    self.date = Date.parse(date) if date.is_a?(String)
    self.publication_date = date - announcement_days.days
    self.notification_date = publication_date
  end
end