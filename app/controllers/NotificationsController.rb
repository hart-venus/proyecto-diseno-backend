class NotificationsController < ApplicationController
    before_action :set_student_inbox, only: [:index, :mark_as_read, :destroy]
  
    def index
      @notifications = @inbox.notifications.order(created_at: :desc)
      render json: @notifications
    end
  
    def create
      @notification = Notification.new(notification_params)
      if @notification.save
        render json: @notification, status: :created
      else
        render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
      end
    end
  
    def mark_as_read
      @notification = @inbox.notifications.find(params[:id])
      if @notification.update(status: 'READ')
        render json: @notification
      else
        render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
      end
    end
  
    def destroy
      @notification = @inbox.notifications.find(params[:id])
      if @notification.status == 'READ'
        @notification.destroy
        head :no_content
      else
        render json: { error: 'Cannot delete unread notification' }, status: :unprocessable_entity
      end
    end
  
    def send_notification_to_campus
      campus = params[:campus]
      content = params[:content]
      sender = params[:sender]
  
      if campus.blank? || content.blank? || sender.blank?
        render json: { error: 'Campus, content, and sender are required' }, status: :bad_request
        return
      end
  
      students = Student.where(campus: campus)
      students.each do |student|
        inbox = StudentInbox.find_by_student(student.carne) || StudentInbox.new(student_carne: student.carne)
        notification_params = {
          sender: sender,
          content: content
        }
        inbox.create_notification(notification_params)
        inbox.save
      end
  
      render json: { message: 'Notifications sent successfully' }, status: :ok
    end
  
    private
  
    def set_student_inbox
      @inbox = StudentInbox.find_by_student(params[:student_carne])
      if @inbox.nil?
        render json: { error: 'Student inbox not found' }, status: :not_found
      end
    end
  
    def notification_params
      params.require(:notification).permit(:sender, :content).merge(recipient_id: @inbox.id)
    end
  end