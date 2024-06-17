class CancellationVisitor < ActivityVisitor
  def initialize(observer)
    @observer = observer
  end

  def visit(activity)
    if activity.status == 'CANCELADA'
      @observer.handle_notification(activity, :cancellation)
    end
  end
end