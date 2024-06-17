class SystemDatesController < ApplicationController
  skip_forgery_protection

  def show
    @system_date = SystemDate.current_date
    render json: { date: @system_date.date }
  rescue StandardError => e
    render json: { error: "Error al obtener la fecha del sistema: #{e.message}" }, status: :internal_server_error
  end
  
  def update
    @system_date = SystemDate.current_date
    if params[:system_date] && params[:system_date][:date].present?
      begin
        # Parsear la fecha sin especificar la zona horaria
        @system_date.date = Date.parse(params[:system_date][:date])
        if @system_date.save
          check_activities_on_date_change
          render json: { message: 'Fecha del sistema actualizada exitosamente', date: @system_date.date }
        else
          render json: { error: 'Error al actualizar la fecha del sistema' }, status: :unprocessable_entity
        end
      rescue ArgumentError => e
        render json: { error: "Formato de fecha inválido: #{e.message}" }, status: :bad_request
      rescue StandardError => e
        render json: { error: "Error al actualizar la fecha del sistema: #{e.message}" }, status: :internal_server_error
      end
    else
      render json: { error: 'El parámetro de fecha está faltando' }, status: :bad_request
    end
  end
  
  def increment
    @system_date = SystemDate.current_date
    days = params[:days].to_i
    @system_date.increment(days)
    check_activities_on_date_change
    render json: { message: 'Fecha del sistema incrementada exitosamente', date: @system_date.date }
  rescue StandardError => e
    render json: { error: "Error al incrementar la fecha del sistema: #{e.message}" }, status: :internal_server_error
  end
  
  def decrement
    @system_date = SystemDate.current_date
    days = params[:days].to_i
    @system_date.decrement(days)
    check_activities_on_date_change
    render json: { message: 'Fecha del sistema decrementada exitosamente', date: @system_date.date }
  rescue StandardError => e
    render json: { error: "Error al decrementar la fecha del sistema: #{e.message}" }, status: :internal_server_error
  end
  
  private
  
  def check_activities_on_date_change
    activities = FirestoreDB.col('activities').get.map do |activity_doc|
      Activity.new(activity_doc.data.merge(id: activity_doc.document_id))
    end
  
    publication_visitor = PublicationVisitor.new
    reminder_visitor = ReminderVisitor.new
  
    activities.each do |activity|
      activity.accept(publication_visitor)
      activity.accept(reminder_visitor)
    end
  rescue StandardError => e
    puts "Error al verificar las actividades después del cambio de fecha: #{e.message}"
    # Puedes elegir manejar el error de una manera diferente, como registrarlo o notificar a los administradores
  end
end