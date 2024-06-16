class PublicationVisitor < ActivityVisitor
  def visit(activity)
    system_date = SystemDate.current_date.date

    publication_date = activity.publication_date + activity.publication_days_before.days
    print "Fecha de publicación: #{publication_date}\n"
    if activity.status == 'PLANEADA' && system_date >= publication_date
      puts "=" * 50
      puts "Enviando notificación de anuncio para la actividad:"
      puts "Nombre: #{activity.name}"
      puts "Fecha de publicación: #{publication_date}"
      puts "Campus: #{activity.work_plan_campus}"
      puts "=" * 50

      activity.status = 'NOTIFICADA'
      activity.notification_date = system_date
      activity.announcement_sent = true
      activity.save

      realization_datetime = activity.realization_date.strftime("%d/%m/%Y") + " a las " + activity.realization_time.strftime("%I:%M %p")

      success = NotificationsController.new.send_notification_to_campus(
        campus: activity.work_plan_campus,
        content: "Nueva actividad anunciada: #{activity.name}. Se llevará a cabo el #{realization_datetime}.",
        sender: 'Sistema'
      )

      puts "El envío de la notificación falló" unless success
    end
  end
end