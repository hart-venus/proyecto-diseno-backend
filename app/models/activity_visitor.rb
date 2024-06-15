# app/models/activity_visitor.rb
module ActivityVisitor
    def visit(activity, global_system_date)
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end
  end
  
  # Visitor para notificar a los estudiantes sobre actividades publicadas
  class ActivityPublicationVisitor
    include ActivityVisitor
    
    # Visitar la actividad y notificar si la fecha de publicación ha llegado
    def visit(activity, global_system_date)
      if activity.status == 'PLANEADA' && activity.publication_date <= global_system_date
        activity.update(status: 'NOTIFICADA')

        # Notificar a los estudiantes del campus de la actividad
        # Se comunica con el observer que va a notificar a los estudiantes



      end
    end
  end
  
  # Visitor para recordar a los estudiantes sobre actividades próximas
  class ActivityReminderVisitor
    include ActivityVisitor
    
    # Visitar la actividad y notificar si la fecha de recordatorio ha llegado
    def visit(activity, global_system_date)
      # Si la actividad está notificada y la fecha de recordatorio está en la lista de fechas de recordatorio
      if activity.status == 'NOTIFICADA' && activity.reminder_dates.include?(global_system_date)
        # Notificar a los estudiantes del campus de la actividad
        # Se comunica con el observer que va a notificar a los estudiantes


        
      end
    end
  end