class PublicationVisitor < ActivityVisitor
  def initialize(observer)
    @observer = observer
  end

  def visit(activity)
    system_date = SystemDateglobaldate.current_date.date
    publication_date = activity.publication_date + activity.publication_days_before.days

    if activity.status == 'PLANEADA' && system_date >= publication_date
      activity.status = 'NOTIFICADA'
      activity.notification_date = system_date
      activity.announcement_sent = true
      activity.save

      @observer.handle_notification(activity, :announcement)
    end
  end
end