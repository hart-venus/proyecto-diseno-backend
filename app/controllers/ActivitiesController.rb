class ActivitiesController < ApplicationController
  skip_forgery_protection

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
    activity_params_with_week = activity_params.merge(week: activity_params[:week].to_i)
    activity = Activity.new(activity_params_with_week.except(:poster_file))
    activity.status = 'PLANEADA' # Asignar el estado inicial como "PLANEADA"
    if activity.valid?
      poster_url = upload_poster(params[:poster_file]) if params[:poster_file].present?
      activity.poster_url = poster_url
      activity_ref = FirestoreDB.col('activities').add(activity.attributes)
      activity.id = activity_ref.document_id
      render json: activity.attributes, status: :created
    else
      render json: { error: 'Failed to create activity', details: activity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    activity = Activity.find(params[:id])
    if activity
      if activity.update(activity_params)
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
        activity.add_evidence(evidence_url)
        render json: activity.attributes
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
      activity.activate
      render json: activity.attributes
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  def notify
    activity = Activity.find(params[:id])
    if activity
      poster_file = params[:poster_file]
      if poster_file
        poster_url = upload_poster(poster_file)
        activity.notify(poster_url)
        render json: activity.attributes
      else
        render json: { error: 'Poster file is required' }, status: :bad_request
      end
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  def mark_as_done
    activity = Activity.find(params[:id])
    if activity
      evidence_files = params[:evidence_files]
      if evidence_files && evidence_files.is_a?(Array)
        evidence_urls = evidence_files.map { |file| upload_evidence(file) }
        activity.mark_as_done(evidence_urls)
        render json: activity.attributes
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
      if cancel_reason
        activity.cancel(cancel_reason)
        render json: activity.attributes
      else
        render json: { error: 'Cancel reason is required' }, status: :bad_request
      end
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end

  private

  def activity_params
    params.permit(:work_plan_id, :week, :activity_type, :name, :date, :time, :announcement_days, :reminder_days, :is_remote, :meeting_link, :poster_file, responsible_ids: [])
  end

  def upload_evidence(evidence_file)
    file_path = "activities/#{SecureRandom.uuid}/evidence/#{evidence_file.original_filename}"
    bucket_name = 'projecto-diseno-backend.appspot.com'
    bucket = FirebaseStorage.bucket(bucket_name)
    file_obj = bucket.create_file(evidence_file.tempfile, file_path, content_type: evidence_file.content_type)
    file_obj.public_url
  end

  def upload_poster(poster_file)
    file_path = "activities/#{SecureRandom.uuid}/poster/#{poster_file.original_filename}"
    bucket_name = 'projecto-diseno-backend.appspot.com'
    bucket = FirebaseStorage.bucket(bucket_name)
    file_obj = bucket.create_file(poster_file.tempfile, file_path, content_type: poster_file.content_type)
    file_obj.public_url
  end
end