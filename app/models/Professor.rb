class Professor < ApplicationRecord
  belongs_to :user
  has_many :professor_modifications

  validates :code, presence: true, uniqueness: true
  validates :phone, :cellphone, presence: true
  validates :photo_url, format: { with: URI::DEFAULT_PARSER.make_regexp, message: 'must be a valid URL' }, allow_blank: true

  enum status: { active: 'active', inactive: 'inactive' }

  def activate
    update(status: 'active')
  end

  def deactivate
    update(status: 'inactive')
  end
end