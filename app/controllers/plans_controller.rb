class PlansController < ApplicationController 
    protect_from_forgery with: :null_session
    before_action :authenticate_request!
    before_action :authorize_admin_or_coordinator, only: [:create, :update]
    before_action :set_plan, only: [:show, :update]

    def index 
        plans_ref = FirestoreDB.col('plans').where('active', '==', true)
        plans = plans_ref.get.map do |plan|
            { id: plan.document_id }.merge(plan.data)
        end
        render json: plans
    end

    def show
        # fetch all activities with plan_ref == @plan
        activities_ref = FirestoreDB.col('activities').where('plan_ref', '==', params[:id])
        activities = activities_ref.get.map do |activity|
            { id: activity.document_id }.merge(activity.data)
        end

        render json: { id: @plan.document_id }.merge(@plan.data).merge({ activities: activities })
    end

    def create
        plan_params = params.require(:plan).permit(:nombre, :sede)
        plan = Plan.new(plan_params)
        if plan.valid?
            plan_data = {
                nombre: plan_params[:nombre],
                sede: plan_params[:sede],
                active: true
            }
            plan_ref = FirestoreDB.col('plans').add(plan_data)
            render json: { id: plan_ref.document_id }, status: :created
        else
            render json: { errors: plan.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def update
        target_plan_id = params[:id]
        target_plan_ref = FirestoreDB.doc("plans/#{target_plan_id}")

        plan_params = params.require(:plan).permit(:nombre, :sede, :active)
        target_plan_ref.set(plan_params.to_h, merge: true)
        render json: { id: target_plan_id }, status: :ok
    end


    private

    def set_plan
        @plan = FirestoreDB.doc("plans/#{params[:id]}").get
        render json: { error: 'Plan not found' }, status: :not_found unless @plan.exists?
    end

    def authorize_admin_or_coordinator
        unless ['AsistenteAdmin', 'ProfesorCoordinador'].include?(@current_user[:tipo])
            render json: { error: 'Not authorized' }, status: :forbidden
        end
    end
end