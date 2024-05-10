class ActivityEvidence
    include ActiveModel::Model
    include ActiveModel::Validations
  
    attr_accessor :id, :activity_id, :evidence_type, :evidence_url, :file_path
  
    validates :activity_id, :evidence_type, :evidence_url, presence: true
    validates :evidence_type, inclusion: { in: ['Lista de asistencia', 'Imagen de participantes', 'Grabación de la actividad'] }
  
    def self.create(attributes)
      evidence = new(attributes)
      if evidence.valid?
        file = attributes[:file]
        if file.present?
          file_path = "activity_evidences/#{SecureRandom.uuid}/#{file.original_filename}"
          bucket_name = 'projecto-diseno-backend.appspot.com'
          bucket = FirebaseStorage.bucket(bucket_name)
          file_obj = bucket.create_file(file.tempfile, file_path, content_type: file.content_type)
          evidence.evidence_url = file_obj.public_url
          evidence.file_path = file_path
        end
        evidence_ref = FirestoreDB.col('activity_evidences').add(evidence.attributes)
        evidence.id = evidence_ref.document_id
        evidence
      else
        nil
      end
    end
  
    def update(attributes)
      assign_attributes(attributes)
      if valid?
        file = attributes[:file]
        if file.present?
          # Eliminar el archivo anterior si existe
          delete_previous_file
          file_path = "activity_evidences/#{SecureRandom.uuid}/#{file.original_filename}"
          bucket_name = 'projecto-diseno-backend.appspot.com'
          bucket = FirebaseStorage.bucket(bucket_name)
          file_obj = bucket.create_file(file.tempfile, file_path, content_type: file.content_type)
          self.evidence_url = file_obj.public_url
          self.file_path = file_path
        end
        FirestoreDB.col('activity_evidences').doc(id).update(attributes)
        true
      else
        false
      end
    end
  
    def destroy
      delete_previous_file
      FirestoreDB.col('activity_evidences').doc(id).delete
      true
    end
  
    def attributes
      {
        activity_id: activity_id,
        evidence_type: evidence_type,
        evidence_url: evidence_url,
        file_path: file_path
      }
    end
  
    private
  
    def delete_previous_file
      if file_path.present?
        bucket_name = 'projecto-diseno-backend.appspot.com'
        bucket = FirebaseStorage.bucket(bucket_name)
        file_obj = bucket.file(file_path)
        file_obj.delete if file_obj.present?
      end
    end
  end