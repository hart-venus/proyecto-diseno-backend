class CancellationVisitor < ActivityVisitor
  def visit(activity)
    if activity.status == 'CANCELADA'
      puts "Enviando notificación de cancelación para la actividad: #{activity.name}"

      success = NotificationsController.new.send_notification_to_campus(
        campus: activity.work_plan_campus,
        content: "La actividad '#{activity.name}' ha sido cancelada. Motivo: #{activity.cancel_reason}",
        sender: 'Sistema'
      )

      puts "El envío de la notificación falló" unless success
    end
  end
end