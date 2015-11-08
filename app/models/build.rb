class Build < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  store_accessor :result, [:env_progress, :failed_subject_results,
                           :success_subject_results]

  validates :status, presence: true

  QUEUED = 0
  RUNNING = 1
  COMPLETE = 2
  ERROR = 3

end
