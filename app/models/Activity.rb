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
  
    def self.create(attributes)
      activity = new(attributes)
      if activity.valid?
        file = attributes[:poster]
        if file.present?
          file_path = "activity_posters/#{SecureRandom.uuid}/#{file.original_filename}"
          bucket_name = 'projecto-diseno-backend.appspot.com'
          bucket = FirebaseStorage.bucket(bucket_name)
          file_obj = bucket.create_file(file.tempfile, file_path, content_type: 'application/pdf')
          activity.poster_url = file_obj.public_url
        end
        activity_ref = FirestoreDB.col('activities').add(activity.attributes)
        activity.id = activity_ref.document_id
        activity
      else
        nil
      end
    end
  
    def update(attributes)
      assign_attributes(attributes)
      if valid?
        file = attributes[:poster]
        if file.present?
          delete_poster
          file_path = "activity_posters/#{SecureRandom.uuid}/#{file.original_filename}"
          bucket_name = 'your-bucket-name'
          bucket = FirebaseStorage.bucket(bucket_name)
          file_obj = bucket.create_file(file.tempfile, file_path, content_type: 'application/pdf')
          self.poster_url = file_obj.public_url
        end
        FirestoreDB.col('activities').doc(id).update(attributes.except(:poster))
        true
      else
        false
      end
    end
  
    def destroy
      delete_poster
      FirestoreDB.col('activities').doc(id).delete
      true
    end
  
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
  
    def mark_as_completed(evidences)
      self.status = 'REALIZADA'
      evidences.each do |evidence|
        ActivityEvidence.create(activity_id: id, evidence_type: evidence[:type], evidence_url: evidence[:url])
      end
      FirestoreDB.col('activities').doc(id).update(status: status)
    end
  
    def cancel(reason)
      self.status = 'CANCELADA'
      self.cancellation_reason = reason
      self.cancellation_date = Time.current
      FirestoreDB.col('activities').doc(id).update(
        status: status,
        cancellation_reason: cancellation_reason,
        cancellation_date: cancellation_date
      )
    end
  
    private
  
    def delete_poster
      if poster_url.present?
        bucket_name = 'your-bucket-name'
        bucket = FirebaseStorage.bucket(bucket_name)
        file_path = URI(poster_url).path.sub(%r{^/#{bucket_name}/}, '')
        file_obj = bucket.file(file_path)
        file_obj&.delete
      end
    end
  end