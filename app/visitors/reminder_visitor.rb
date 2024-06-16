class ReminderVisitor < ActivityVisitor
  def visit(activity)
    if activity.status == 'NOTIFICADA'
      current_date = SystemDate.current_date.date

      # Find the next reminder date that is equal to or before the current date
      next_reminder_date = activity.reminder_dates.select { |date| date <= current_date }.max

      if next_reminder_date && (activity.last_reminder_sent_at.nil? || activity.last_reminder_sent_at < next_reminder_date)
        puts "Sending reminder notification for activity: #{activity.name}"
        activity.last_reminder_sent_at = current_date
        activity.save

        success = NotificationsController.new.send_notification_to_campus(
          campus: activity.work_plan_campus,
          content: "Reminder: The activity '#{activity.name}' will take place on #{activity.realization_date} at #{activity.realization_time}.",
          sender: 'System'
        )

        puts "Reminder notification sending failed" unless success
      end
    end
  end
end