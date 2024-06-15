# app/controllers/system_dates_controller.rb
class SystemDatesController < ApplicationController
  skip_forgery_protection

  def show
    @system_date = SystemDate.current_date
    render json: { date: @system_date.date }
  end

  # app/controllers/system_dates_controller.rb
  # app/controllers/system_dates_controller.rb
  # app/controllers/system_dates_controller.rb
  def update
    @system_date = SystemDate.current_date
    if params[:system_date] && params[:system_date][:date].present?
      # Parse the date without specifying the time zone
      @system_date.date = Date.parse(params[:system_date][:date])
      if @system_date.save
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
    render json: { message: 'System date incremented successfully', date: @system_date.date }
  end

  def decrement
    @system_date = SystemDate.current_date
    days = params[:days].to_i
    @system_date.decrement(days)
    render json: { message: 'System date decremented successfully', date: @system_date.date }
  end
end