class MessagesController < ApplicationController
    def create
      message_params = params.require(:message).permit(:student_id, :subject, :content)
      message = Message.new(message_params)
      if message.save
        render json: message, status: :created
      else
        render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end