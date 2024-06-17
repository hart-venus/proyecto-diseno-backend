class ActivityObserver
    def initialize
      @notification_controller = NotificationsController.new
    end
  
    def handle_notification(activity, notification_type)
      case notification_type
      when :announcement
        send_announcement_notification(activity)
      when :reminder
        send_reminder_notification(activity)
      when :cancellation
        send_cancellation_notification(activity)
      else
        raise ArgumentError, "Unknown notification type: #{notification_type}"
      end
    end
  
    private
  
    def send_announcement_notification(activity)
      realization_date_str = activity.realization_date.strftime("%d/%m/%Y")
      realization_time_str = activity.realization_time.to_s
  
      success = @notification_controller.send_notification_to_campus(
        campus: activity.work_plan_campus,
        content: "Nueva actividad anunciada: #{activity.name}. Se llevará a cabo el #{realization_date_str} a las #{realization_time_str}.",
        sender: 'Sistema'
      )
  
      puts "El envío de la notificación falló" unless success
    end
  
    def send_reminder_notification(activity)
      realization_date = Date.parse(activity.realization_date)
      realization_date_str = realization_date.strftime("%d/%m/%Y")
      realization_time_str = activity.realization_time.to_s
  
      success = @notification_controller.send_notification_to_campus(
        campus: activity.work_plan_campus,
        content: "Recordatorio: La actividad '#{activity.name}' se llevará a cabo el #{realization_date_str} a las #{realization_time_str}. ¡No te la pierdas!",
        sender: 'Sistema'
      )
  
      puts "El envío de la notificación de recordatorio falló" unless success
    end
  
    def send_cancellation_notification(activity)
      success = @notification_controller.send_notification_to_campus(
        campus: activity.work_plan_campus,
        content: "La actividad '#{activity.name}' ha sido cancelada. Motivo: #{activity.cancel_reason}",
        sender: 'Sistema'
      )
  
      puts "El envío de la notificación falló" unless success
    end
  end