# app/models/system_date.rb
class SystemDateglobaldate
  include ActiveModel::Model
  attr_accessor :id, :date

  def self.current_date
    doc_ref = FirestoreDB.col('system_dates').doc('current')
    doc = doc_ref.get

    if doc.exists?
      new(id: doc.document_id, date: doc.data[:date].to_date)
    else
      new(id: 'current', date: Date.today)
    end
  end

  def save
    doc_ref = FirestoreDB.col('system_dates').doc(id)
    doc_ref.set({ date: date })
  end

  def increment(days)
    self.date += days.days
    save
  end

  def decrement(days)
    self.date -= days.days
    save
  end
end