class NotificationsController < ApplicationController
  skip_forgery_protection
  before_action :set_student_inbox, only: [:index, :mark_as_read, :destroy, :create]

  def index
    # Sort notifications by created_at in descending order
    @notifications = @inbox.notifications.sort { |a, b| b[:created_at] <=> a[:created_at]}
    render json: @notifications
  end

  def create
    @notification = Notification.create(notification_params)
    if @notification.valid?
      @inbox.add_notification(@notification)
      render json: @notification, status: :created
    else
      render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def mark_as_read
    @notification = @inbox.update(params[:id], {status: 'READ'})
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

  def send_notification_to_campus(campus:, content:, sender:)
    if campus.blank? || content.blank? || sender.blank?
      puts "Error: Campus, content, and sender are required"
      return false
    end
  
    students = Student.find_by_campus(campus)
    students.each do |student|
      inbox = StudentInbox.find_by_student(student.carne)
      notification_params = {
        sender: sender,
        content: content,
        recipient_id: student.carne
      }
      inbox.add_notification(Notification.create(notification_params))
    end
  
    puts "Notifications sent successfully"
    true
  end

  private

  def set_student_inbox
    @inbox = StudentInbox.find_by_student(params[:student_carne])
    if @inbox.nil?
      render json: { error: 'Student inbox not found' }, status: :not_found
    end
  end

  def notification_params
      params.require(:notification).permit(:sender, :content).merge(recipient_id: params[:student_carne])
  end
end