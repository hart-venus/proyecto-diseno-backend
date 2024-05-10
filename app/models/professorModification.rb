class ProfessorModification
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :id, :professor_code, :modified_by, :modification_type, :previous_data, :new_data, :timestamp

  validates :professor_code, :modified_by, :modification_type, presence: true

  def self.create(attributes)
    modification = new(attributes)
    if modification.valid?
      modification_ref = FirestoreDB.col('professor_modifications').add(modification.attributes)
      modification.id = modification_ref.document_id
      modification
    else
      nil
    end
  end

  def attributes
    {
      professor_code: professor_code,
      modified_by: modified_by,
      modification_type: modification_type,
      previous_data: previous_data,
      new_data: new_data,
      timestamp: timestamp || Time.current
    }
  end
end