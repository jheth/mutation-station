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

  after_update :send_pusher

  def send_pusher
    # Send Pusher on status/value changes
    begin
      hash = {
        id: self.id,
        status: self.status,
        last_sha: self.last_sha,
        status_text: self.status_text,
        url: "/repositories/#{self.repository.id}/builds/#{self.id}",
      }
      Pusher.trigger('build_status_channel', 'client-build-update', hash)
    rescue Pusher::Error => e
      # (Pusher::AuthenticationError, Pusher::HTTPError, or Pusher::Error)
    end
  end

  def status_text
    case status
    when QUEUED
      'Queued'
    when RUNNING
      'Running'
    when COMPLETE
      'Complete'
    when ERROR
      'Error'
    end
  end
end
