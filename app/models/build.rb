class Build < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  store_accessor :result, [:env_progress, :failed_subject_results,
                           :success_subject_results]

  validates :status, presence: true

  after_update :send_build_completed_email

  QUEUED = 0
  RUNNING = 1
  COMPLETE = 2
  ERROR = 3

  def send_progress_status(message: nil, status: nil)
    # Send Pusher on status/value changes
    self.status = status unless status.nil?

    begin
      hash = {
        id: self.id,
        status: self.status,
        status_text: self.status_text,
        message: message,
        url: "/repositories/#{self.repository.id}/builds/#{self.id}",
      }
      Pusher.trigger('status_channel', 'client-build-update', hash)
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

  private

  def send_build_completed_email
    if status == 2
      BuildNotifier.build_finished(user, self).deliver
    end
  end
end
