class ActivityCommentsController < ApplicationController
  skip_forgery_protection

  def create
    activity_id = params[:activity_id]
    user_id = params[:user_id]
    content = params[:content]
    parent_comment_id = params[:parent_comment_id]

    puts "Parámetros recibidos:"
    puts "activity_id: #{activity_id}"
    puts "user_id: #{user_id}"
    puts "content: #{content}"
    puts "parent_comment_id: #{parent_comment_id}"

    # Buscar el profesor por su código de usuario
    professor = find_professor_by_id(user_id)
    if professor.nil?
      puts "Profesor no encontrado"
      render json: { error: 'Professor not found' }, status: :not_found
      return
    end

    puts "Profesor encontrado:"
    puts professor.inspect


    if professor[:'code'].present? && professor[:'full_name'].present?
      comment = ActivityComment.new(
        activity_id: activity_id,
        professor_code: professor[:'code'],
        professor_name: professor[:'full_name'],
        content: content,
        parent_comment_id: parent_comment_id
      )

      puts "Comentario creado:"
      puts comment.inspect

      if comment.valid?
        # Guardar el comentario en Firestore y obtener el ID generado
        comment_ref = FirestoreDB.col('comments').add(comment.attributes)
        comment.id = comment_ref.document_id

        puts "Comentario guardado correctamente"
        render json: comment.attributes, status: :created
      else
        puts "Error al guardar el comentario"
        puts comment.errors.full_messages
        render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
      end
    else
      puts "El código o nombre del profesor está faltando"
      render json: { error: 'Professor code or name is missing' }, status: :unprocessable_entity
    end
  end

  def activity_base_comments
    activity_id = params[:activity_id]
  
    base_comments = FirestoreDB.col('comments')
                                .where('activity_id', '==', activity_id)
                                .where('parent_comment_id', '==', nil)
                                .get.to_a
  
    comments_data = base_comments.map do |comment_doc|
      comment_data = comment_doc.data.dup
      comment_data['id'] = comment_doc.document_id
      comment_data
    end
  
    render json: comments_data, status: :ok
  end

  def direct_reply_comments
    parent_comment_id = params[:parent_comment_id]
  
    reply_comments = FirestoreDB.col('comments')
                                 .where('parent_comment_id', '==', parent_comment_id)
                                 .get.to_a
  
    comments_data = reply_comments.map do |comment_doc|
      comment_data = comment_doc.data.dup
      comment_data['id'] = comment_doc.document_id
      comment_data
    end
  
    render json: comments_data, status: :ok
  end

  private

  def find_professor_by_id(user_id)
    professor_docs = FirestoreDB.col('professors').where('user_id', '==', user_id).get.to_a
    if professor_docs.empty?
      nil
    else
      professor_data = professor_docs.first.data.dup
      professor_data['id'] = professor_docs.first.document_id
      professor_data
    end
  end
end