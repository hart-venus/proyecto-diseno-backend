class ReminderVisitor < ActivityVisitor
  def initialize(observer)
    @observer = observer
  end

  def visit(activity)
    if activity.status == 'NOTIFICADA'
      current_date = SystemDateglobaldate.current_date.date
      next_reminder_date = activity.reminder_dates.select { |date| date <= current_date }.max

      if next_reminder_date && (activity.last_reminder_sent_at.nil? || activity.last_reminder_sent_at < next_reminder_date)
        activity.last_reminder_sent_at = current_date
        activity.save

        @observer.handle_notification(activity, :reminder)
      end
    end
  end
end