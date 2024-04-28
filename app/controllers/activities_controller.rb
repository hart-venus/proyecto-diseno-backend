class ActivitiesController < ApplicationController
    protect_from_forgery with: :null_session
    before_action :authenticate_request! 
    before_action :authorize_admin_or_coordinator, only: [:create, :update]
    before_action :set_activity, only: [:show, :update]

    def index 
        activities_ref = FirestoreDB.col('activities').where('active', '==', true)
        activities = activities_ref.get.map do |activity|
            { id: activity.document_id }.merge(activity.data)
        end
        render json: activities
    end

    def show 
        # fetch all users with id on responsables
        responsable_info = @activity[:responsables].map do |user_id|
            user = FirestoreDB.doc("users/#{user_id}").get
            # skip if user is not active
            if user.exists? && user[:active]
                { id: user_id }.merge(user.data.except(:password))
            else 
                { id: user_id }
            end
        end

        render json: { id: @activity.document_id }.merge(@activity.data).merge({ responsables: responsable_info })
    end

    def create 
        activity_params = params.require(:activity).permit(:indole, :semana, :nombre, :fecha, {:responsables => []}, {:recordatorios => []}, :presencial, :enlace, :plan_ref) 
        activity = Activity.new(activity_params)
        if activity.valid?
            activity_data = activity_params.to_h.merge({ estado: 'Planeada', active: true })
            puts activity_data
            activity_ref = FirestoreDB.col('activities').add(activity_data)
            render json: { id: activity_ref.document_id }, status: :created
        else
            render json: { errors: activity.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def update
        target_activity_id = params[:id]
        target_activity_ref = FirestoreDB.doc("activities/#{target_activity_id}")

        activity_params = params.require(:activity).permit(:indole, :semana, :nombre, :fecha, {:responsables => []}, {:recordatorios => []}, :presencial, :enlace, :plan_ref, :estado, :active)
        target_activity_ref.set(activity_params.to_h, merge: true)
        render json: { id: target_activity_id }, status: :ok
    end

    private

    def set_activity
        @activity = FirestoreDB.doc("activities/#{params[:id]}").get
        render json: { error: 'Activity not found' }, status: :not_found unless @activity.exists?
    end

    def authorize_admin_or_coordinator
        unless ['AsistenteAdmin', 'ProfesorCoordinador'].include?(@current_user[:tipo])
            render json: { error: 'Not authorized' }, status: :forbidden
        end
    end
end