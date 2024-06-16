class Activity
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :id, :work_plan_id, :week, :activity_type, :name, :realization_date, :realization_time,
                :responsible_ids, :publication_days_before, :reminder_frequency_days, :is_remote, :meeting_link,
                :poster_url, :status, :cancel_reason, :evidences, :notification_date, :publication_date,
                :last_reminder_sent_at, :announcement_sent, :work_plan_campus

  validates :work_plan_id, :week, :activity_type, :name, :realization_date, :realization_time,
            :responsible_ids, :publication_days_before, :reminder_frequency_days, :is_remote, :status,
            presence: true
  validates :week, inclusion: { in: 1..16 }
  validates :status, inclusion: { in: ['PLANEADA', 'NOTIFICADA', 'REALIZADA', 'CANCELADA'] }
  validates :realization_time, presence: true, format: { with: /\A(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]\z/, message: "must be in HH:MM format" }

  def self.create(attributes)
    activity = new(attributes)
    if activity.valid?
      activity.calculate_dates
      activity.announcement_sent = false
      activity.work_plan_campus = WorkPlan.find(activity.work_plan_id).campus

      activity_ref = FirestoreDB.col('activities').add(activity.attributes)
      activity.id = activity_ref.document_id
      activity
    else
      activity # return the activity object so that we can inspect its errors
    end
  rescue => e
    puts "Error in Activity.create: #{e.message}"
    nil
  end

  def self.find(id)
    doc = FirestoreDB.col('activities').doc(id).get
    return nil unless doc.exists?

    data = doc.data.dup
    data['id'] = doc.document_id
    new(data)
  end

  def self.find_by_work_plan(work_plan_id)
    activities = []
    FirestoreDB.col('activities').where('work_plan_id', '==', work_plan_id).get do |activity_doc|
      data = activity_doc.data.dup
      data['id'] = activity_doc.document_id
      activities << new(data)
    end
    activities
  end

  def update(attributes)
    attrs = self.attributes.dup
    attrs.merge!(attributes)
    return false unless valid?

    calculate_dates
    self.work_plan_campus = WorkPlan.find(self.work_plan_id).campus
    FirestoreDB.col('activities').doc(id).update(attrs)
    true
  end

  def save
    if valid?
      FirestoreDB.col('activities').doc(id).set(attributes)
      true
    else
      false
    end
  end

  def accept(visitor)
    visitor.visit(self)
  end

  def reminder_dates
    return [] unless notification_date && reminder_frequency_days && realization_date

    dates = []
    current_date = notification_date
    while current_date < realization_date
      current_date += reminder_frequency_days.days
      dates << current_date if current_date < realization_date
    end
    dates
  end

  def cancel(reason)
    update(status: 'CANCELADA', cancel_reason: reason)
  end

  def self.init(params)
    activity = new
    activity.work_plan_id = params[:work_plan_id]
    activity.week = params[:week]
    activity.activity_type = params[:activity_type]
    activity.name = params[:name]
    activity.realization_date = params[:realization_date]
    activity.realization_time = params[:realization_time]
    activity.responsible_ids = params[:responsible_ids]
    activity.publication_days_before = params[:publication_days_before]
    activity.reminder_frequency_days = params[:reminder_frequency_days]
    activity.is_remote = params[:is_remote]
    activity.meeting_link = params[:meeting_link]
    activity.poster_url = params[:poster_url]
    activity
  end

  def attributes
    {
      id: id,
      work_plan_id: work_plan_id,
      week: week,
      activity_type: activity_type,
      name: name,
      realization_date: realization_date,
      realization_time: realization_time,
      responsible_ids: responsible_ids,
      publication_days_before: publication_days_before,
      reminder_frequency_days: reminder_frequency_days,
      is_remote: is_remote,
      meeting_link: meeting_link,
      poster_url: poster_url,
      status: status,
      cancel_reason: cancel_reason,
      evidences: evidences,
      notification_date: notification_date,
      publication_date: publication_date,
      last_reminder_sent_at: last_reminder_sent_at,
      announcement_sent: announcement_sent,
      work_plan_campus: work_plan_campus
    }
  end

  def calculate_dates
    self.realization_date = Date.parse(realization_date) if realization_date.is_a?(String)
    self.publication_date = realization_date - publication_days_before.days
    self.notification_date = publication_date
  end
end