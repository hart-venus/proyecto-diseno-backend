class ActivityComment
    include ActiveModel::Model
    include ActiveModel::Validations
  
    attr_accessor :id, :activity_id, :professor_id, :professor_name, :content, :created_at, :parent_comment_id
  
    validates :activity_id, :professor_id, :professor_name, :content, presence: true
  
    def self.create(attributes)
      comment = new(attributes)
      if comment.valid?
        comment_ref = FirestoreDB.col('activity_comments').add(comment.attributes)
        comment.id = comment_ref.document_id
        comment
      else
        nil
      end
    end
  
    def update(attributes)
      assign_attributes(attributes)
      if valid?
        FirestoreDB.col('activity_comments').doc(id).update(attributes)
        true
      else
        false
      end
    end
  
    def destroy
      FirestoreDB.col('activity_comments').doc(id).delete
      true
    end
  
    def attributes
      {
        activity_id: activity_id,
        professor_id: professor_id,
        professor_name: professor_name,
        content: content,
        created_at: created_at || Time.current,
        parent_comment_id: parent_comment_id
      }
    end
  
    def replies
      ActivityComment.where(parent_comment_id: id)
    end
  
    def self.where(conditions)
      query = FirestoreDB.col('activity_comments')
      conditions.each do |field, value|
        query = query.where(field.to_s, '==', value)
      end
      query.get.map { |doc| ActivityComment.new(doc.data.merge(id: doc.document_id)) }
    end
  
    def self.get_comments_by_activity(activity_id, filters = {})
      query = FirestoreDB.col('activity_comments').where('activity_id', '==', activity_id)
      filters.each do |field, value|
        query = query.where(field.to_s, '==', value)
      end
      query.get.map { |doc| ActivityComment.new(doc.data.merge(id: doc.document_id)) }
    end
  end