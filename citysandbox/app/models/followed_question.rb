class FollowedQuestion < ActiveRecord::Base
  belongs_to :user
  belongs_to :question
  
  validates :question_id, :presence => true
  validates :user_id, :presence => true
end
