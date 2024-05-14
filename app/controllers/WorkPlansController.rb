class WorkPlansController < ApplicationController
  skip_forgery_protection
  before_action :set_user, only: [:create, :update]
  before_action :validate_coordinator, only: [:create, :update]

  def index
    work_plan_docs = FirestoreDB.col('work_plans').get
    @work_plans = work_plan_docs.map do |doc|
      work_plan_data = doc.data
      WorkPlan.new(work_plan_data.merge(id: doc.document_id))
    end
    render json: @work_plans.map(&:attributes), status: :ok
  end

  def show
    work_plan_doc = FirestoreDB.col('work_plans').doc(params[:id]).get
    if work_plan_doc.exists?
      work_plan_data = work_plan_doc.data
      @work_plan = WorkPlan.new(work_plan_data.merge(id: work_plan_doc.document_id))
      render json: @work_plan.attributes, status: :ok
    else
      render json: { error: 'Work plan not found' }, status: :not_found
    end
  end

  def create
    if @professor.present?
      @work_plan = WorkPlan.create(work_plan_params.merge(coordinator_id: @professor[:'code']))
      if @work_plan
        render json: @work_plan.attributes.merge(id: @work_plan.id), status: :created
      else
        render json: { errors: @work_plan.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def update
    work_plan_ref = FirestoreDB.col('work_plans').doc(params[:id])
    work_plan_doc = work_plan_ref.get
    if work_plan_doc.exists?
      work_plan_data = work_plan_doc.data.dup
      work_plan_params.slice(:start_date, :end_date).each do |key, value|
        work_plan_data[key] = value
      end
      @work_plan = WorkPlan.new(work_plan_data.merge(id: params[:id], coordinator_id: @professor['id']))
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

  def current
    today = Date.today
    work_plans = FirestoreDB.col('work_plans')
      .where('start_date', '<=', today)
      .where('end_date', '>=', today)
      .get
    @current_work_plan = work_plans.map { |doc| WorkPlan.new(doc.data.merge(id: doc.document_id)) }.first
    if @current_work_plan
      next_activity = @current_work_plan.next_activity
      render json: { work_plan: @current_work_plan, next_activity: next_activity }
    else
      render json: { message: 'No current work plan found' }, status: :not_found
    end
  end

  private

  def work_plan_params
    params.require(:work_plan).permit(:start_date, :end_date, :campus, :active)
  end

  def activity_params
    params.permit(:status, :responsible_id)
  end

  def set_user
    user_id = params[:user_id]
    professor_doc = FirestoreDB.col('professors').where('user_id', '==', user_id).get.first
    if professor_doc
      @professor = professor_doc.data.merge(id: professor_doc.document_id)
      @user = User.find_by_id(@professor['user_id'])
    else
      render json: { error: 'Professor not found' }, status: :not_found
    end
  end

  def validate_coordinator
    unless @professor && @professor[:'coordinator']
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end