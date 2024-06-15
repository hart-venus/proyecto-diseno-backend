class NotificationCenter
  def self.notify(activity, message_type, message)
    # Retrieve the associated students' inboxes based on the activity's work plan campus
    student_inboxes = get_student_inboxes_by_work_plan_campus(activity.work_plan_id)

    # Create and deliver the message to the students' inboxes
    message_data = {
      activity_id: activity.id,
      message_type: message_type,
      content: message,
      created_at: Time.now
    }

    student_inboxes.each do |inbox|
      inbox.add_message(message_data)
    end
  end

  private

  def self.get_student_inboxes_by_work_plan_campus(work_plan_id)
    # Retrieve the work plan's campus from Firebase
    work_plan_doc = FirestoreDB.col('work_plans').doc(work_plan_id).get
    campus = work_plan_doc.data[:campus]

    # Retrieve all student inboxes for the given campus from Firebase
    student_inboxes = []

    student_docs = FirestoreDB.col('students').where('campus', '==', campus).get
    student_docs.each do |student_doc|
      student_id = student_doc.document_id
      inbox = find_or_create_student_inbox(student_id)
      student_inboxes << inbox
    end

    student_inboxes
  end

  def self.find_or_create_student_inbox(student_id)
    # Find the student inbox by student ID from Firebase
    inbox_doc = FirestoreDB.col('student_inboxes').where('student_id', '==', student_id)

    if inbox_doc
      # If the inbox exists, create a StudentInbox instance from the document data
      inbox_data = inbox_doc.data
      inbox_data[:id] = inbox_doc.document_id
      StudentInbox.new(inbox_data)
    else
      # If the inbox doesn't exist, create a new one and save it to Firebase
      inbox = StudentInbox.new(student_id: student_id)
      inbox_ref = FirestoreDB.col('student_inboxes').add(inbox.attributes)
      inbox.id = inbox_ref.document_id
      inbox
    end
  end
end