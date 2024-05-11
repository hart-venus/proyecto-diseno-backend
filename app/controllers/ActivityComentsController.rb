class ActivityComentsController < ApplicationController
    skip_forgery_protection
  
    def index
      activity_id = params[:activity_id]
      comments = FirestoreDB.col('activity_comments').where('activity_id', '==', activity_id).get
      render json: comments.map { |doc| doc.data.merge(id: doc.document_id) }
    end
  
    def show
      comment_doc = FirestoreDB.col('activity_comments').doc(params[:id]).get
      if comment_doc.exists?
        render json: comment_doc.data.merge(id: comment_doc.document_id)
      else
        render json: { error: 'Comment not found' }, status: :not_found
      end
    end
  
    def create
      comment_params = {
        activity_id: params[:activity_id],
        professor_id: params[:professor_id],
        professor_name: params[:professor_name],
        content: params[:content],
        parent_comment_id: params[:parent_comment_id]
      }
  
      @comment = ActivityComment.new(comment_params)
  
      if @comment.valid?
        comment_ref = FirestoreDB.col('activity_comments').add(@comment.attributes)
        @comment.id = comment_ref.document_id
        render json: @comment, status: :created
      else
        render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
      end
    end
  
    def update
      comment_ref = FirestoreDB.col('activity_comments').doc(params[:id])
      comment_doc = comment_ref.get
  
      if comment_doc.exists?
        comment_params = {
          content: params[:content]
        }
  
        @comment = ActivityComment.new(comment_params.merge(id: comment_doc.document_id))
  
        if @comment.valid?
          comment_ref.update(@comment.attributes.except(:id))
          render json: @comment
        else
          render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
        end
      else
        render json: { error: 'Comment not found' }, status: :not_found
      end
    end
  
    def destroy
      comment_ref = FirestoreDB.col('activity_comments').doc(params[:id])
      comment_doc = comment_ref.get
  
      if comment_doc.exists?
        comment_ref.delete
        head :no_content
      else
        render json: { error: 'Comment not found' }, status: :not_found
      end
    end
  
    def replies
      parent_comment_id = params[:id]
      replies = FirestoreDB.col('activity_comments')
                           .where('parent_comment_id', '==', parent_comment_id)
                           .get
      render json: replies.map { |doc| doc.data.merge(id: doc.document_id) }
    end
  end