class WorkPlan
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :id, :coordinator_id, :start_date, :end_date, :activities

  validates :coordinator_id, :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  def self.create(attributes)
    work_plan = new(attributes)
    if work_plan.valid?
      work_plan_ref = FirestoreDB.col('work_plans').add(work_plan.attributes)
      work_plan.id = work_plan_ref.document_id
      work_plan
    else
      nil
    end
  end

  def attributes
    {
      coordinator_id: coordinator_id,
      start_date: start_date,
      end_date: end_date,
      activities: activities || []
    }
  end

  def add_activity(activity)
    self.activities ||= []
    self.activities << activity
    FirestoreDB.col('work_plans').doc(id).update(activities: activities)
  end

  def get_activities(filters = {})
    query = FirestoreDB.col('activities').where('work_plan_id', '==', id)

    filters.each do |field, value|
      query = query.where(field.to_s, '==', value)
    end

    query.get.map { |doc| Activity.new(doc.data.merge(id: doc.document_id)) }
  end

  private

  def end_date_after_start_date
    if end_date.present? && start_date.present? && end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end
end