class PublicationVisitor < ActivityVisitor
  def visit(activity)
    if activity.status == 'PLANEADA' && Date.current >= activity.publication_date
      puts "Sending announcement notification for activity: #{activity.name}"
      activity.status = 'NOTIFICADA'
      activity.notification_date = Date.current
      activity.announcement_sent = true
      activity.save
      NotificationsController.new.notify_announcement(activity, activity.work_plan_campus)
    end
  end
end