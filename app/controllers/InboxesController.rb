class InboxesController < ApplicationController
    def index
      student_id = params[:student_id]
      messages = Message.where(student_id: student_id)
      render json: messages
    end
  
    def show
      message = Message.find(params[:id])
      if message
        render json: message
      else
        render json: { error: 'Message not found' }, status: :not_found
      end
    end
  
    def mark_as_read
      message = Message.find(params[:id])
      if message
        message.read = true
        if message.save
          render json: message
        else
          render json: { error: 'Failed to mark message as read' }, status: :unprocessable_entity
        end
      else
        render json: { error: 'Message not found' }, status: :not_found
      end
    end
  
    def destroy
      message = Message.find(params[:id])
      if message
        FirestoreDB.col('messages').doc(message.id).delete
        head :no_content
      else
        render json: { error: 'Message not found' }, status: :not_found
      end
    end
  end