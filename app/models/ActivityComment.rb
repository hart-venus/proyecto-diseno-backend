class ActivityComment
    include ActiveModel::Model
    include ActiveModel::Validations
  
    attr_accessor :id, :activity_id, :professor_id, :professor_name, :content, :created_at, :parent_comment_id
  
    validates :activity_id, :professor_id, :professor_name, :content, presence: true
  
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

  end