# Guardar la fecha actual del sistema en la base de datos
# Cargar la fecha actual del sistema desde la base de datos o usar la fecha actual si no hay una fecha guardada

class GlobalSystemDate
  COLLECTION_NAME = 'global_system_date'.freeze
  DOCUMENT_ID = 'current_date'.freeze

  class << self
    def current_date
      doc_ref = FirestoreDB.col(COLLECTION_NAME).doc(DOCUMENT_ID)
      doc_snapshot = doc_ref.get

      if doc_snapshot.exists?
        date_str = doc_snapshot.data['date']
        Date.parse(date_str)
      else
        # If no document is found, use the current date as the default
        current_date = Date.today
        set_date(current_date)
        current_date
      end
    end

    def set_date(new_date)
      # Update the global system date in the database
      doc_ref = FirestoreDB.col(COLLECTION_NAME).doc(DOCUMENT_ID)
      doc_ref.set({ date: new_date.to_s })
    end

    def increment_date(days)
      current_date = self.current_date
      new_date = current_date + days.to_i
      set_date(new_date)
      new_date
    end

    def decrement_date(days)
      current_date = self.current_date
      new_date = current_date - days.to_i
      set_date(new_date)
      new_date
    end

    def reset_date
      current_date = Date.today
      set_date(current_date)
      current_date
    end
  end
end