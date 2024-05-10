class Activity
    include ActiveModel::Model
    include ActiveModel::Validations
  
    attr_accessor :id, :work_plan_id, :week, :activity_type, :name, :description, :date_time,
                  :responsible_professors, :announcement_days, :reminder_days, :location,
                  :remote_link, :poster_url, :status, :cancellation_reason, :cancellation_date
  
    validates :work_plan_id, :week, :activity_type, :name, :date_time, :responsible_professors,
              :announcement_days, :reminder_days, :location, presence: true
    validates :week, inclusion: { in: 1..16 }
    validates :activity_type, inclusion: { in: ['Orientadoras', 'Motivacionales', 'De apoyo a la vida estudiantil', 'De orden técnico', 'De recreación'] }
    validates :status, inclusion: { in: ['PLANEADA', 'NOTIFICADA', 'REALIZADA', 'CANCELADA'] }
    validates :announcement_days, :reminder_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :poster_url, format: { with: URI::DEFAULT_PARSER.make_regexp, message: 'must be a valid URL' }, allow_blank: true
  
    def attributes
      {
        work_plan_id: work_plan_id,
        week: week,
        activity_type: activity_type,
        name: name,
        description: description,
        date_time: date_time,
        responsible_professors: responsible_professors,
        announcement_days: announcement_days,
        reminder_days: reminder_days,
        location: location,
        remote_link: remote_link,
        poster_url: poster_url,
        status: status,
        cancellation_reason: cancellation_reason,
        cancellation_date: cancellation_date
      }
    end
  end