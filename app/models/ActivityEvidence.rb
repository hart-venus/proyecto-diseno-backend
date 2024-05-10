class ActivityEvidence
    include ActiveModel::Model
    include ActiveModel::Validations
  
    attr_accessor :id, :activity_id, :evidence_type, :evidence_url, :file_path
  
    validates :activity_id, :evidence_type, :evidence_url, presence: true
    validates :evidence_type, inclusion: { in: ['Lista de asistencia', 'Imagen de participantes', 'Grabación de la actividad'] }
    def attributes
      {
        activity_id: activity_id,
        evidence_type: evidence_type,
        evidence_url: evidence_url,
        file_path: file_path
      }
    end
  
  end