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
      update_params = activity.attributes.dup # Crear una copia mutable de los atributos
  
      # Actualizar atributos individualmente si están presentes en los parámetros
      update_params[:work_plan_id] = params[:work_plan_id] if params[:work_plan_id].present?
      update_params[:week] = params[:week].to_i if params[:week].present?
      update_params[:activity_type] = params[:activity_type] if params[:activity_type].present?
      update_params[:name] = params[:name] if params[:name].present?
      update_params[:date] = params[:date] if params[:date].present?
      update_params[:time] = params[:time] if params[:time].present?
      update_params[:responsible_ids] = params[:responsible_ids] if params[:responsible_ids].present?
      update_params[:announcement_days] = params[:announcement_days] if params[:announcement_days].present?
      update_params[:reminder_days] = params[:reminder_days] if params[:reminder_days].present?
      update_params[:is_remote] = params[:is_remote] if params[:is_remote].present?
      update_params[:meeting_link] = params[:meeting_link] if params[:meeting_link].present?
      update_params[:status] = activity.status
      update_params[:cancel_reason] = activity.cancel_reason
      update_params[:evidences] = activity.evidences
  
      if params[:poster_file].present?
        poster_url = upload_poster(params[:poster_file])
        update_params[:poster_url] = poster_url
      end
  
      updated_activity = Activity.new(update_params)
      updated_activity.id = activity.id
  
      if updated_activity.valid?
        FirestoreDB.col('activities').doc(activity.id).set(updated_activity.attributes)
        render json: updated_activity.attributes
      else
        render json: { error: 'Failed to update activity', details: updated_activity.errors.full_messages }, status: :unprocessable_entity
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
      update_attrs = {
        status: 'NOTIFICADA'
      }
      
      FirestoreDB.col('activities').doc(activity.id).update(update_attrs)
      
      render json: { message: 'Activity notified successfully' }
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
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
        update_attrs = {
          status: 'CANCELADA',
          cancel_reason: cancel_reason
        }
  
        FirestoreDB.col('activities').doc(activity.id).update(update_attrs)
  
        render json: { message: 'Activity cancelled successfully' }
      else
        render json: { error: 'Cancel reason is required' }, status: :bad_request
      end
    else
      render json: { error: 'Activity not found' }, status: :not_found
    end
  end
  
  def notified
    notified_activities = FirestoreDB.col('activities')
                                   .where('status', '==', 'NOTIFICADA')
                                   .get
                                   .map { |activity_doc| activity_doc.data.merge(id: activity_doc.document_id) }
  
    if notified_activities.any?
      render json: notified_activities
    else
      render json: { message: 'No notified activities found' }
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