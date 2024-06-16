class ActivitiesController < ApplicationController
  skip_forgery_protection
  require 'firebase'

  def index
    work_plan_id = params[:work_plan_id]
    if work_plan_id
      activities = Activity.find_by_work_plan(work_plan_id)
      render json: activities.map(&:attributes)
    else
      render json: { error: 'Work plan ID is required' }, status: :bad_request
    end
  end

  def show
    activity = Activity.find(params[:id])
    if activity
      render json: activity.attributes
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  def create
    puts "Received parameters: #{params.inspect}"
    activity_params = params.except(:activity).permit(:work_plan_id, :week, :activity_type, :name, :realization_date,
    :realization_time, :responsible_ids, :publication_days_before,
    :reminder_frequency_days, :is_remote, :meeting_link, :poster_file,
    responsible_ids: [])

  
    activity = Activity.init(activity_params.except(:activity))
    activity.status = 'PLANEADA'
  
    system_date = SystemDate.current_date
    system_date = system_date.date
    if system_date
      activity.publication_date = system_date
      print("Publication Date2: #{activity.publication_date}\n")
    else
      puts "Error: SystemDate.current_date returned nil"
      render json: { error: 'Failed to set publication date' }, status: :unprocessable_entity
      return
    end
  
    work_plan = WorkPlan.find(activity.work_plan_id)
    if work_plan
      activity.work_plan_campus = work_plan.campus
    else
      puts "Error: WorkPlan not found for work_plan_id: #{activity.work_plan_id}"
      render json: { error: 'Invalid work plan ID' }, status: :unprocessable_entity
      return
    end
  
    if activity.valid?
      poster_url = upload_poster(params[:poster_file]) if params[:poster_file].present?
      activity.poster_url = poster_url
      activity_ref = Activity.create(activity.attributes)
  
      if activity_ref
        # Check if the activity should be published immediately
        publication_visitor = PublicationVisitor.new
        begin
          activity_ref.accept(publication_visitor)
        rescue => e
          puts "Error occurred while accepting PublicationVisitor: #{e.message}"
          puts e.backtrace.join("\n")
        end
  
        # Check if the activity has any reminders to be sent
        reminder_visitor = ReminderVisitor.new
        begin
          activity_ref.accept(reminder_visitor)
        rescue => e
          puts "Error occurred while accepting ReminderVisitor: #{e.message}"
          puts e.backtrace.join("\n")
        end
  
        render json: activity_ref.attributes, status: :created
      else
        puts "Failed to create activity: #{activity.errors.full_messages.join(', ')}"
        render json: { error: 'Failed to create activity' }, status: :unprocessable_entity
      end
    else
      puts "Activity is invalid: #{activity.errors.full_messages.join(', ')}"
      render json: { error: 'Failed to create activity', details: activity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    activity = Activity.find(params[:id])
    if activity
      update_params = activity_params.except(:poster_file)
      if params[:poster_file].present?
        poster_url = upload_poster(params[:poster_file])
        update_params[:poster_url] = poster_url
      end

      if activity.update(update_params)
        check_activity_with_visitors(activity)
        render json: activity.attributes
      else
        render json: { error: 'Failed to update activity', details: activity.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  def add_evidence
    activity = Activity.find(params[:id])
    if activity
      evidence_file = params[:evidence_file]
      if evidence_file
        evidence_url = upload_evidence(evidence_file)
        activity_evidences = activity.evidences || []
        activity_evidences << evidence_url

        # Update the evidences attribute in Firebase
        FirestoreDB.col('activities').doc(activity.id).update({ evidences: activity_evidences })

        # Re-fetch the updated activity to return the latest state
        updated_activity = Activity.find(activity.id)
        render json: { message: 'Evidence added successfully', activity: updated_activity.attributes }
      else
        render json: { error: 'Evidence file is required' }, status: :bad_request
      end
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  def activate
    activity = Activity.find(params[:id])
    if activity
      visitor = PublicationVisitor.new
      activity.accept(visitor)
      render json: activity.attributes
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  def send_reminders
    activities = Activity.all
    visitor = ReminderVisitor.new
    activities.each do |activity|
      activity.accept(visitor)
    end
    render json: { message: 'Reminders sent successfully' }
  end

  def mark_as_done
    activity = Activity.find(params[:id])

    if activity
      evidence_files = params[:evidence_files]

      if evidence_files.present? && evidence_files.is_a?(Array)
        evidence_urls = []

        evidence_files.each do |file|
          evidence_url = upload_evidence(file)
          evidence_urls << evidence_url
        end

        update_attrs = {
          status: 'REALIZADA',
          evidences: activity.evidences.to_a.concat(evidence_urls)
        }

        FirestoreDB.col('activities').doc(activity.id).update(update_attrs)

        render json: { message: 'Activity marked as done successfully' }
      else
        render json: { error: 'Evidence files are required' }, status: :bad_request
      end
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  def cancel
    activity = Activity.find(params[:id])

    if activity
      cancel_reason = params[:cancel_reason]

      if cancel_reason.present?
        activity.cancel(cancel_reason)

        visitor = CancellationVisitor.new
        activity.accept(visitor)

        render json: { message: 'Activity cancelled successfully' }
      else
        render json: { error: 'Cancel reason is required' }, status: :bad_request
      end
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  def notified
    work_plan_id = params[:work_plan_id]

    if work_plan_id.present?
      notified_activities = FirestoreDB.col('activities')
                                       .where('status', '==', 'NOTIFICADA')
                                       .where('work_plan_id', '==', work_plan_id)
                                       .get
                                       .map { |activity_doc| activity_doc.data.merge(id: activity_doc.document_id) }

      if notified_activities.any?
        render json: notified_activities
      else
        render json: { message: 'No notified activities found for the given work plan ID' }
      end
    else
      render json: { error: 'Work plan ID is required' }, status: :bad_request
    end
  end

  def poster
    activity = Activity.find(params[:id])

    if activity && activity.poster_url.present?
      # Obtener el nombre del archivo del póster de la URL
      file_name = File.basename(URI.parse(activity.poster_url).path)

      # Descargar el contenido del archivo del póster desde Firebase Storage
      bucket_name = 'projecto-diseno-backend.appspot.com'
      bucket = FirebaseStorage.bucket(bucket_name)
      file = bucket.file(file_name)

      if file.present?
        file_content = file.download

        # Enviar el archivo como respuesta para descarga
        send_data file_content, filename: file_name, type: file.content_type, disposition: 'attachment'
      else
        render json: { error: 'Poster file not found in storage' }, status: :not_found
      end
    else
      render json: { error: 'Poster URL not found for the activity' }, status: :not_found
    end
  end

  def should_notify
    activity = Activity.find(params[:id])

    if activity
      system_date = SystemDate.current_date.date
      publication_date = activity.realization_date - activity.publication_days_before.days

      if system_date >= publication_date
        render json: { should_notify: true }
      else
        render json: { should_notify: false }
      end
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  private

  def activity_params
    params.permit(:work_plan_id, :week, :activity_type, :name, :realization_date, :realization_time,
                  :publication_days_before, :reminder_frequency_days, :is_remote, :meeting_link,
                  :poster_file, responsible_ids: [])
  end

  def upload_evidence(evidence_file)
    file_path = "activities/#{SecureRandom.uuid}/evidence/#{evidence_file.original_filename}"
    bucket_name = 'projecto-diseno-backend.appspot.com'
    bucket = FirebaseStorage.bucket(bucket_name)
    file_obj = bucket.create_file(evidence_file.tempfile, file_path, content_type: evidence_file.content_type)

    # Set the ACL to allow public access
    file_obj.acl.public!

    file_obj.public_url
  end

  def upload_poster(poster_file)
    file_path = "activities/#{SecureRandom.uuid}/poster/#{poster_file.original_filename}"
    bucket_name = 'projecto-diseno-backend.appspot.com'
    bucket = FirebaseStorage.bucket(bucket_name)
    file_obj = bucket.create_file(poster_file.tempfile, file_path, content_type: poster_file.content_type)

    # Set the ACL to allow public access
    file_obj.acl.public!

    file_obj.public_url
  end

  def check_activity_with_visitors(activity)
    publication_visitor = PublicationVisitor.new
    reminder_visitor = ReminderVisitor.new

    activity.accept(publication_visitor)
    activity.accept(reminder_visitor)
  end
end