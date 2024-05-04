# app/models/professor_modification.rb
class ProfessorModification < ApplicationRecord
    belongs_to :professor
    belongs_to :administrative_assistant
    
    validates :modification_type, presence: true, inclusion: { in: ['create', 'update', 'deactivate'] }
    validates :modification_date, presence: true
    validates :previous_data, presence: true, if: :update_or_deactivate?
    validates :new_data, presence: true, if: :create_or_update?
    
    private
    
  end