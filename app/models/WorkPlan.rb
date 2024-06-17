class WorkPlan
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :id, :coordinator_id, :start_date, :end_date, :campus, :active

  validates :coordinator_id, :start_date, :end_date, :campus, presence: true
  validates :active, inclusion: { in: [true, false] }
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

  def self.find(id)
    doc = FirestoreDB.col('work_plans').doc(id).get
    if doc.exists?
      data = doc.data.dup
      data['id'] = doc.document_id
      new(data)
    else
      nil
    end
  end

  def update(attributes)
    merge_attributes(attributes)
    if valid?
      FirestoreDB.col('work_plans').doc(id).update(attributes)
      true
    else
      false
    end
  end

  def deactivate
    self.active = false
    FirestoreDB.col('work_plans').doc(id).update(active: false)
  end

  def attributes
    {
      id: id,
      coordinator_id: coordinator_id,
      start_date: start_date,
      end_date: end_date,
      campus: campus,
      active: active
    }
  end

  private

  def end_date_after_start_date
    if end_date.present? && start_date.present? && end_date < start_date
      errors.add(:end_date, "debe ser posterior a la fecha de inicio")
    end
  end
end