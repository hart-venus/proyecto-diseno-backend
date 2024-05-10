class ActivitiesController < ApplicationController
    skip_forgery_protection
  
    def create
        work_plan_id = params[:work_plan_id]
        work_plan_ref = FirestoreDB.col('work_plans').doc(work_plan_id)
        work_plan_doc = work_plan_ref.get
      
        if work_plan_doc.exists?
          activity_params_with_poster = activity_params.merge(poster: params[:activity][:poster])
          @activity = Activity.new(activity_params_with_poster.merge(work_plan_id: work_plan_id))
      
          if @activity.valid?
            @activity = Activity.create(activity_params_with_poster.merge(work_plan_id: work_plan_id))
            render json: @activity, status: :created
          else
            render json: { errors: @activity.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Work plan not found' }, status: :not_found
        end
      end
      
      private
      
      def activity_params
        params.require(:activity).permit(
          :week, :activity_type, :name, :description, :date_time,
          :announcement_days, :reminder_days, :location, :remote_link,
          :status, responsible_professors: []
        ).tap do |permitted_params|
          required_params = %i[week activity_type name description date_time announcement_days reminder_days location poster status]
          missing_params = required_params.select { |param| permitted_params[param].blank? }
          if missing_params.any?
            raise ActionController::ParameterMissing.new(missing_params.join(', '))
          end
        end
      end
end