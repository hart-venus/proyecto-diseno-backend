class WorkPlansController < ApplicationController
  skip_forgery_protection
  def index
    work_plans = FirestoreDB.col('work_plans').get
    @work_plans = work_plans.map { |doc| WorkPlan.new(doc.data.merge(id: doc.document_id)) }
    render json: @work_plans
  end

  def show
    work_plan_doc = FirestoreDB.col('work_plans').doc(params[:id]).get
    if work_plan_doc.exists?
      @work_plan = WorkPlan.new(work_plan_doc.data.merge(id: work_plan_doc.document_id))
      render json: @work_plan
    else
      render json: { error: 'Work plan not found' }, status: :not_found
    end
  end

  def create
    @work_plan = WorkPlan.create(work_plan_params)
    if @work_plan
      render json: @work_plan, status: :created
    else
      render json: { errors: @work_plan.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    work_plan_ref = FirestoreDB.col('work_plans').doc(params[:id])
    work_plan_doc = work_plan_ref.get
    
    if work_plan_doc.exists?
      work_plan_data = work_plan_doc.data.dup
      work_plan_params.slice(:coordinator_id, :start_date, :end_date).each do |key, value|
        work_plan_data[key] = value
      end
      
      @work_plan = WorkPlan.new(work_plan_data.merge(id: params[:id]))
      if @work_plan.valid?
        work_plan_ref.set(work_plan_data)
        updated_work_plan_doc = work_plan_ref.get
        render json: updated_work_plan_doc.data.merge(id: updated_work_plan_doc.document_id)
      else
        render json: { errors: @work_plan.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Work plan not found' }, status: :not_found
    end
  end

  def destroy
    @work_plan = WorkPlan.new(id: params[:id])
    if @work_plan.destroy
      head :no_content
    else
      render json: { errors: ['Failed to delete work plan'] }, status: :unprocessable_entity
    end
  end

  def activities
    @work_plan = WorkPlan.new(id: params[:id])
    if @work_plan.valid?
      @activities = @work_plan.get_activities(activity_params)
      render json: @activities
    else
      render json: { errors: @work_plan.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def work_plan_params
    params.require(:work_plan).permit(:coordinator_id, :start_date, :end_date)
  end

  def activity_params
    params.permit(:status, :responsible_id)
  end
end