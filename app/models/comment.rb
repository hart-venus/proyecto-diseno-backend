class Comment < ApplicationRecord
    belongs_to :activity
    belongs_to :user
  
    has_many :replies, class_name: 'Comment', foreign_key: 'parent_comment_id'
    belongs_to :parent_comment, class_name: 'Comment', optional: true
  
    validates :content, presence: true
  
    def username
      user.full_name
    end
  end