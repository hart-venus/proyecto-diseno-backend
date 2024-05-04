class AsistenteAdministrativa < ApplicationRecord
  belongs_to :user
  has_many :professor_modifications
  
  validates :user, presence: true
  validate :user_must_be_admin

  private

  def user_must_be_admin
    errors.add(:user, 'must be an admin') unless user.admin?
  end
end