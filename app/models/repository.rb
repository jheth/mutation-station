class Repository < ActiveRecord::Base
  belongs_to :user

  validates :name, :clone_url, presence: true
end
