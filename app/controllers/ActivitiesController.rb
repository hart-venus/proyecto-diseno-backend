class ActivitiesController < ApplicationController
  skip_forgery_protection

  def index
    activities = FirestoreDB.col('activities').get
    render json: activities.map { |doc| doc.data.merge(id: doc.document_id) }
  end

  def show
    activity_doc = FirestoreDB.col('activities').doc(params[:id]).get
    if activity_doc.exists?
      render json: activity_doc.data.merge(id: activity_doc.document_id)
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  def create
    work_plan_id = params[:work_plan_id]
    work_plan_doc = FirestoreDB.col('work_plans').doc(work_plan_id).get

    unless work_plan_doc.exists?
      render json: { error: 'Work plan not found' }, status: :unprocessable_entity
      return
    end

    activity_params = {
      work_plan_id: work_plan_id,
      week: params[:week].to_i,
      activity_type: params[:activity_type],
      name: params[:name],
      description: params[:description],
      date_time: params[:date_time],
      responsible_professors: params[:responsible_professors],
      announcement_days: params[:announcement_days].to_i,
      reminder_days: params[:reminder_days].to_i,
      location: params[:location],
      remote_link: params[:remote_link],
      status: params[:status] || 'PLANEADA',
      publication_date: calculate_publication_date(params[:date_time], params[:announcement_days]),
      reminder_dates: calculate_reminder_dates(params[:date_time], params[:reminder_days]),
      evidences: []
    }

    @activity = Activity.new(activity_params)

    if @activity.valid?
      poster = params[:poster]
      if poster.present?
        poster_url = upload_poster(poster)
        @activity.poster_url = poster_url
      end

      activity_ref = FirestoreDB.col('activities').add(@activity.attributes)
      @activity.id = activity_ref.document_id

      render json: @activity, status: :created
    else
      render json: { errors: @activity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    activity_ref = FirestoreDB.col('activities').doc(params[:id])
    activity_doc = activity_ref.get

    if activity_doc.exists?
      activity_params = {
        work_plan_id: params[:work_plan_id],
        week: params[:week].to_i,
        activity_type: params[:activity_type],
        name: params[:name],
        description: params[:description],
        date_time: params[:date_time],
        responsible_professors: params[:responsible_professors],
        announcement_days: params[:announcement_days].to_i,
        reminder_days: params[:reminder_days].to_i,
        location: params[:location],
        remote_link: params[:remote_link]
      }

      @activity = Activity.new(activity_params.merge(id: activity_doc.document_id))

      if @activity.valid?
        poster = params[:poster]
        if poster.present?
          delete_poster(@activity.poster_url) if @activity.poster_url.present?
          poster_url = upload_poster(poster)
          @activity.poster_url = poster_url
        end

        activity_ref.update(@activity.attributes.except(:id))

        render json: @activity
      else
        render json: { errors: @activity.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  def mark_as_notified
    activity_ref = FirestoreDB.col('activities').doc(params[:id])
    activity_doc = activity_ref.get

    if activity_doc.exists?
      activity_ref.update(status: 'NOTIFICADA')
      render json: { message: 'Activity marked as notified' }
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  def mark_as_completed
    activity_ref = FirestoreDB.col('activities').doc(params[:id])
    activity_doc = activity_ref.get

    if activity_doc.exists?
      evidences = params[:evidences]
      if evidences.present?
        @activity = Activity.new(activity_doc.data.merge(id: activity_doc.document_id))
        @activity.status = 'REALIZADA'

        evidences_data = []
        evidences.each do |evidence|
          evidence_data = create_evidence(@activity.id, evidence[:type], evidence[:file])
          evidences_data << evidence_data
        end

        @activity.evidences = evidences_data

        activity_ref.update(status: @activity.status, evidences: @activity.evidences)

        render json: @activity
      else
        render json: { errors: ['At least one evidence is required to mark the activity as completed'] }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  def cancel
    activity_ref = FirestoreDB.col('activities').doc(params[:id])
    activity_doc = activity_ref.get

    if activity_doc.exists?
      cancellation_reason = params[:cancellation_reason]
      cancellation_date = params[:cancellation_date]

      if cancellation_reason.present? && cancellation_date.present?
        @activity = Activity.new(activity_doc.data.merge(id: activity_doc.document_id))
        @activity.status = 'CANCELADA'
        @activity.cancellation_reason = cancellation_reason
        @activity.cancellation_date = cancellation_date

        activity_ref.update(
          status: @activity.status,
          cancellation_reason: @activity.cancellation_reason,
          cancellation_date: @activity.cancellation_date
        )

        render json: @activity
      else
        render json: { errors: ['Cancellation reason and date are required to cancel the activity'] }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  private

  def calculate_publication_date(date_time, announcement_days)
    DateTime.parse(date_time) - announcement_days.days
  end

  def calculate_reminder_dates(date_time, reminder_days)
    reminder_dates = []
    current_date = DateTime.parse(date_time)

    reminder_days.times do
      current_date -= 1.day
      reminder_dates << current_date
    end

    reminder_dates
  end

  def upload_poster(poster)
    file_path = "activity_posters/#{SecureRandom.uuid}/#{poster.original_filename}"
    bucket_name = 'projecto-diseno-backend.appspot.com'
    bucket = FirebaseStorage.bucket(bucket_name)
    file_obj = bucket.create_file(poster.tempfile, file_path, content_type: poster.content_type)
    file_obj.public_url
  end

  def delete_poster(poster_url)
    if poster_url.present?
      bucket_name = 'projecto-diseno-backend.appspot.com'
      bucket = FirebaseStorage.bucket(bucket_name)
      file_path = URI(poster_url).path.sub(%r{^/#{bucket_name}/}, '')
      file_obj = bucket.file(file_path)
      file_obj&.delete
    end
  end

  def create_evidence(activity_id, evidence_type, file)
    evidence_data = {
      activity_id: activity_id,
      evidence_type: evidence_type
    }

    if file.present?
      file_path = upload_evidence(file)
      evidence_data[:evidence_url] = file_path
      evidence_data[:file_path] = file_path
    end

    evidence_data
  end

  def upload_evidence(file)
    file_path = "activity_evidences/#{SecureRandom.uuid}/#{file.original_filename}"
    bucket_name = 'projecto-diseno-backend.appspot.com'
    bucket = FirebaseStorage.bucket(bucket_name)
    file_obj = bucket.create_file(file.tempfile, file_path, content_type: file.content_type)
    file_obj.public_url
  end

  def comments
    activity_id = params[:id]
    activity_doc = FirestoreDB.col('activities').doc(activity_id).get

    if activity_doc.exists?
      activity = Activity.new(activity_doc.data.merge(id: activity_doc.document_id))
      comments = activity.comments
      render json: comments
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

end