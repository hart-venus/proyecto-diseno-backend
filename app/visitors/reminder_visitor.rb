class ReminderVisitor < ActivityVisitor
  def visit(activity)
    if activity.status == 'NOTIFICADA' && activity.reminder_dates.include?(Date.current)
      puts "Sending reminder notification for activity: #{activity.name}"
      activity.last_reminder_sent_at = Date.current
      activity.save
      NotificationsController.new.notify_reminder(activity, activity.work_plan_campus)
    end
  end
end