
class GlobaldateController < ApplicationController
  skip_forgery_protection
  
  def showglobaldate
    @system_date_globaldate = SystemDateglobaldate.current_date
    render json: { date: @system_date_globaldate.date }
  end

  def updateglobaldate
    @system_date_globaldate = SystemDateglobaldate.current_date
    if params[:system_date_globaldate] && params[:system_date_globaldate][:date].present?
      # Parse the date without specifying the time zone
      @system_date_globaldate.date = Date.parse(params[:system_date_globaldate][:date])
      if @system_date_globaldate.save
        check_activities_on_date_change
        render json: { message: 'System date updated successfully', date: @system_date_globaldate.date }
      else
        render json: { error: 'Failed to update system date' }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Date parameter is missing' }, status: :bad_request
    end
  end

  def incrementglobaldate
    @system_date_globaldate = SystemDateglobaldate.current_date
    days = params[:days].to_i
    @system_date_globaldate.increment(days)
    check_activities_on_date_change
    render json: { message: 'System date incremented successfully', date: @system_date_globaldate.date }
  end

  def decrementglobaldate
    @system_date_globaldate = SystemDateglobaldate.current_date
    days = params[:days].to_i
    @system_date_globaldate.decrement(days)
    check_activities_on_date_change
    render json: { message: 'System date decremented successfully', date: @system_date_globaldate.date }
  end

  private

  def check_activities_on_date_change
    activities = FirestoreDB.col('activities').get.map do |activity_doc|
      Activity.new(activity_doc.data.merge(id: activity_doc.document_id))
    end
  
    publication_visitor = PublicationVisitor.new
    reminder_visitor = ReminderVisitor.new
  
    activities.each do |activity|
      activity.accept(publication_visitor)
      activity.accept(reminder_visitor)
    end
  end
end