class CancellationVisitor < ActivityVisitor
  def visit(activity)
    if activity.status == 'CANCELADA'
      puts "Sending cancellation notification for activity: #{activity.name}"
      NotificationsController.new.notify_cancellation(activity)
    end
  end
end