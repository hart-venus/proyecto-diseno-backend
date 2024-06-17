class ReminderVisitor < ActivityVisitor
  def visit(activity)
    if activity.status == 'NOTIFICADA'
      current_date = SystemDateglobaldate.current_date.date

      # Find the next reminder date that is equal to or before the current date
      next_reminder_date = activity.reminder_dates.select { |date| date <= current_date }.max

      if next_reminder_date && (activity.last_reminder_sent_at.nil? || activity.last_reminder_sent_at < next_reminder_date)
        puts "Enviando notificación de recordatorio para la actividad: #{activity.name}"
        activity.last_reminder_sent_at = current_date
        activity.save

        # Parse the realization_date string into a date object
        realization_date = Date.parse(activity.realization_date)
        realization_date_str = realization_date.strftime("%d/%m/%Y")
        realization_time_str = activity.realization_time.to_s

        success = NotificationsController.new.send_notification_to_campus(
          campus: activity.work_plan_campus,
          content: "Recordatorio: La actividad '#{activity.name}' se llevará a cabo el #{realization_date_str} a las #{realization_time_str}. ¡No te la pierdas!",
          sender: 'Sistema'
        )

        puts "El envío de la notificación de recordatorio falló" unless success
      end
    end
  end
end