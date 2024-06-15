# app/controllers/student_inboxes_controller.rb
class StudentInboxesController < ApplicationController
    skip_forgery_protection
  
    def index
      student_id = params[:student_id]
      student = Student.find(student_id)
  
      if student
        inbox = StudentInbox.find_or_create_by_student_id(student.carne)
        render json: inbox.messages
      else
        render json: { error: 'Student not found' }, status: :not_found
      end
    end
  
    def mark_as_read
      student_id = params[:student_id]
      message_id = params[:message_id]
      student = Student.find(student_id)
  
      if student
        inbox = StudentInbox.find_or_create_by_student_id(student.carne)
        message = inbox.messages.find { |msg| msg['id'] == message_id }
  
        if message
          message['read'] = true
          inbox.save
          render json: { message: 'Message marked as read' }
        else
          render json: { error: 'Message not found' }, status: :not_found
        end
      else
        render json: { error: 'Student not found' }, status: :not_found
      end
    end
  
    def destroy
      student_id = params[:student_id]
      message_id = params[:message_id]
      student = Student.find(student_id)
  
      if student
        inbox = StudentInbox.find_or_create_by_student_id(student.carne)
        message = inbox.messages.find { |msg| msg['id'] == message_id }
  
        if message
          inbox.messages.delete(message)
          inbox.save
          render json: { message: 'Message deleted' }
        else
          render json: { error: 'Message not found' }, status: :not_found
        end
      else
        render json: { error: 'Student not found' }, status: :not_found
      end
    end
  end