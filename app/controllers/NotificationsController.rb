class NotificationsController < ApplicationController
  skip_forgery_protection
  before_action :set_student_inbox, only: [:index, :mark_as_read, :destroy]

  def index
    @notifications = @inbox.notifications.sort { |a, b| b[:created_at] <=> a[:created_at] }
    render json: @notifications
  end

  def create
    @notification = Notification.create(notification_params)
    if @notification.valid?
      student_carne = params[:student_carne]
      work_plan_campus = params[:work_plan_campus]
      
      if student_carne.present?
        inbox = StudentInbox.find_by_student(student_carne)
        if inbox && inbox.student.campus == work_plan_campus
          inbox.add_notification(@notification)
        end
      else
        # Broadcast notification to all students' inboxes in the same campus
        StudentInbox.all.each do |inbox|
          if inbox.student.campus == work_plan_campus
            inbox.add_notification(@notification)
          end
        end
      end
      
      render json: @notification, status: :created
    else
      render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def mark_as_read
    @notification = @inbox.update(params[:id], { status: 'READ' })
    unless @notification.nil?
      render json: @notification
    else
      render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @inbox.delete(params[:id])
      render json: { message: 'Notification deleted successfully' }, status: :ok
    else
      render json: { error: 'Notification not found' }, status: :not_found
    end
  end

  def notify_announcement(activity, work_plan_campus)
    @notification_params = {
      sender: 'System',
      content: "New activity announced: #{activity.name}. It will take place on #{activity.realization_date} at #{activity.realization_time}.",
      recipient_id: 'all',
      work_plan_campus: work_plan_campus
    }
    create
  end

  def notify_reminder(activity, work_plan_campus)
    @notification_params = {
      sender: 'System',
      content: "Reminder: The activity '#{activity.name}' will take place on #{activity.realization_date} at #{activity.realization_time}.",
      recipient_id: 'all',
      work_plan_campus: work_plan_campus
    }
    create
  end

  def notify_cancellation(activity, work_plan_campus)
    @notification_params = {
      sender: 'System',
      content: "Activity '#{activity.name}' has been cancelled. Reason: #{activity.cancel_reason}",
      recipient_id: 'all',
      work_plan_campus: work_plan_campus
    }
    create
  end

  private

  def set_student_inbox
    @inbox = StudentInbox.find_by_student(params[:student_carne])
    if @inbox.nil?
      render json: { error: 'Student inbox not found' }, status: :not_found
    end
  end

  def notification_params
    @notification_params.merge(recipient_id: params[:student_carne])
  end
end