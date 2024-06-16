class StudentInboxController < ApplicationController
    skip_forgery_protection
    before_action :set_student_inbox, only: [:show, :fuzzy_search, :filter_by_status]
  
    def show
      # Sort notifications by created_at in descending order
      @notifications = @inbox.notifications.sort { |a, b| b[:created_at] <=> a[:created_at] }
      render json: @notifications
    end
  
    def fuzzy_search
      query = params[:query].downcase
  
      if query.present?
        notifications = @inbox.notifications.select do |notification|
          notification[:sender].downcase.include?(query) ||
            notification[:content].downcase.include?(query) ||
            notification[:status].downcase.include?(query)
        end
  
        if notifications.empty?
          render json: { message: 'No se encontraron notificaciones que coincidan con la búsqueda' }, status: :not_found
        else
          render json: notifications
        end
      else
        render json: { error: 'Debe proporcionar un término de búsqueda' }, status: :bad_request
      end
    end
  
    def filter_by_status
      status = params[:status]
  
      if status.present?
        notifications = @inbox.notifications.select { |notification| notification[:status] == status }
  
        if notifications.empty?
          render json: { message: "No se encontraron notificaciones con el estado '#{status}'" }, status: :not_found
        else
          render json: notifications
        end
      else
        render json: { error: 'Debe proporcionar un estado para filtrar' }, status: :bad_request
      end
    end

    def mark_as_read
        notification_id = params[:notification_id]
        @notification = @inbox.update(notification_id, { status: 'READ' })
        if @notification
          render json: @notification
        else
          render json: { error: 'Notification not found' }, status: :not_found
        end
      end
  
    private
  
    def set_student_inbox
        @inbox = StudentInbox.find_by_student(params[:student_carne])
        if @inbox.nil?
          render json: { error: 'Student inbox not found' }, status: :not_found
          return
        end
      end
    
      def destroy
        if @inbox.delete(params[:notification_id])
          render json: { message: 'Notification deleted successfully' }, status: :ok
        else
          render json: { error: 'Notification not found' }, status: :not_found
        end
      end
  end