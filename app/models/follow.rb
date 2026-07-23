class Follow < ApplicationRecord
  belongs_to :follower, class_name: 'User'
  belongs_to :following, class_name: 'User'

  validates :follower_id, uniqueness: { scope: :following_id }
  validates :follower_id, presence: true
  validates :following_id, presence: true
  
  validate :cannot_follow_self

  private

  def cannot_follow_self
    errors.add(:base, "Users cannot follow themselves") if follower_id == following_id
  end
end
