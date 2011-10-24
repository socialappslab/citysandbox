class FollowedEvent < ActiveRecord::Base
  belongs_to :events
  belongs_to :user
  
  validates :user_id, :presence => true
  validates :question_id, :presence => true
end