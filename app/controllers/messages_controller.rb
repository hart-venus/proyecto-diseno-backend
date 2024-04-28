class MessagesController < ApplicationController
    protect_from_forgery with: :null_session 
    before_action :authenticate_request!
    before_action :authorize_admin_or_professor, only: [:create]
    before_action :set_message, only: [:show]

    def index
        messages_ref = FirestoreDB.col('messages').where('active', '==', true)
        messages = messages_ref.get.map do |message|
            { id: message.document_id }.merge(message.data)
        end
        render json: messages
    end

    def show 
        # fetch user with id on sender
        sender = FirestoreDB.doc("users/#{@message[:sender]}").get
        sender_info = { id: @message[:sender] }.merge(sender.data.except(:password))

        render json: { id: @message.document_id }.merge(@message.data).merge({ sender: sender_info })
    end

    def create
        message_params = params.require(:message).permit(:activity_ref, :date, :content)
        message = Message.new(message_params)
        if message.valid?
            message_data = message_params.to_h.merge({ active: true, sender: @current_user[:document_id] })
            message_ref = FirestoreDB.col('messages').add(message_data)
            render json: { id: message_ref.document_id }, status: :created
        else
            render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
        end
    end

    private

    def set_message
        @message = FirestoreDB.doc("messages/#{params[:id]}").get
        render json: { error: 'Message not found' }, status: :not_found unless @message.exists?
    end

    def authorize_admin_or_professor
        unless ['AsistenteAdmin', 'ProfesorCoordinador', 'Profesor'].include?(@current_user[:tipo])
            render json: { error: 'Not authorized' }, status: :forbidden
        end
    end
end