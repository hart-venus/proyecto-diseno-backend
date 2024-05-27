# app/repositories/professor_collection.rb
class ProfessorCollection < BaseCollection
    def all
      collection.get.map { |doc| doc.data.merge(id: doc.document_id) }
    end
  
    def get_bycode(code)
      professor_doc = FirestoreDB.col('professors').where('code', '==', code).get.first
      if professor_doc.present?
        user_id = professor_doc.data[:user_id]
        if user_id.present?
          user_doc = FirestoreDB.col('users').doc(user_id).get
          if user_doc.exists?
            render json: user_doc.data.merge(id: user_doc.document_id)
          else
            render json: { error: 'User not found for the professor' }, status: :not_found
          end
        else
          render json: { error: 'User not associated with the professor' }, status: :not_found
        end
      else
        render json: { error: 'Professor not found' }, status: :not_found
      end
    end
  end