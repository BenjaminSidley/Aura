class User < ApplicationRecord
  has_secure_password

  has_many :reviews, dependent: :destroy
  has_many :playlists, dependent: :destroy
  has_many :follows_as_follower, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :follows_as_following, class_name: 'Follow', foreign_key: 'following_id', dependent: :destroy
  has_many :following, through: :follows_as_follower, source: :following
  has_many :followers, through: :follows_as_following, source: :follower

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :username, presence: true, uniqueness: true

  # Follow/unfollow helper methods
  def follow(other_user)
    following << other_user unless following.include?(other_user)
  end

  def unfollow(other_user)
    following.delete(other_user)
  end

  def following?(other_user)
    following.include?(other_user)
  end

  # Called from Last.fm auth callback
  def connect_lastfm_from_session(session_key, username)
    ApplicationRecord.transaction do
      if username.present?
        User.where(lastfm_username: username).where.not(id: id).update_all(
          lastfm_username: nil,
          lastfm_session_key: nil,
          lastfm_connected: false,
          updated_at: Time.current
        )

        self.lastfm_username = username
      end

      self.lastfm_session_key = session_key
      self.lastfm_connected = true

      save!(validate: false)
    end
  rescue ActiveRecord::RecordNotUnique
    conflicting = User.find_by(lastfm_username: username)
    if conflicting && conflicting != self
      conflicting.update!(
        lastfm_username: nil,
        lastfm_session_key: nil,
        lastfm_connected: false
      )
      retry
    end
    false
  rescue StandardError => e
    Rails.logger.warn("[User#connect_lastfm_from_session] #{e.class}: #{e.message}")
    false
  end

  def disconnect_lastfm!
    update(
      lastfm_username: nil,
      lastfm_session_key: nil,
      lastfm_connected: false
    )
  end
end