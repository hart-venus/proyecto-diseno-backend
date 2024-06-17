class SystemDate
  include ActiveModel::Model
  attr_accessor :id, :date

  def self.current_date
    doc_ref = FirestoreDB.col('system_dates').doc('current')
    doc = doc_ref.get

    if doc.exists?
      new(id: doc.document_id, date: doc.data[:date].to_date)
    else
      # Si no existe la fecha del sistema, se establece la fecha actual
      new(id: 'current', date: Date.today).save
      puts "No se encontró la fecha del sistema. Se estableció la fecha actual: #{Date.today}"
      new(id: 'current', date: Date.today)
    end
  rescue StandardError => e
    puts "Error al obtener la fecha del sistema: #{e.message}"
    raise
  end

  def save
    doc_ref = FirestoreDB.col('system_dates').doc(id)
    doc_ref.set({ date: date })
    puts "Fecha del sistema guardada exitosamente: #{date}"
  rescue StandardError => e
    puts "Error al guardar la fecha del sistema: #{e.message}"
    raise
  end

  def increment(days)
    self.date += days.days
    save
    puts "Fecha del sistema incrementada en #{days} días. Nueva fecha: #{date}"
  end

  def decrement(days)
    self.date -= days.days
    save
    puts "Fecha del sistema decrementada en #{days} días. Nueva fecha: #{date}"
  end
end