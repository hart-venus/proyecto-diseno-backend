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