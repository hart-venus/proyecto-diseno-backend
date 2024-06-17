class GlobaldateController < ApplicationController
  skip_forgery_protection

  def show
    @system_date = SystemDate.current_date
    render json: { date: @system_date.date }
  end

  def update
    @system_date = SystemDate.current_date
    if params[:system_date] && params[:system_date][:date].present?
      # Parse the date without specifying the time zone
      @system_date.date = Date.parse(params[:system_date][:date])
      if @system_date.save
        check_activities_on_date_change
        render json: { message: 'System date updated successfully', date: @system_date.date }
      else
        render json: { error: 'Failed to update system date' }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Date parameter is missing' }, status: :bad_request
    end
  end

  def increment
    @system_date = SystemDate.current_date
    days = params[:days].to_i
    @system_date.increment(days)
    check_activities_on_date_change
    render json: { message: 'System date incremented successfully', date: @system_date.date }
  end

  def decrement
    @system_date = SystemDate.current_date
    days = params[:days].to_i
    @system_date.decrement(days)
    check_activities_on_date_change
    render json: { message: 'System date decremented successfully', date: @system_date.date }
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