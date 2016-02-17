require 'active_support'

class Notification
  include Mongoid::Document

  field :created_at, type: DateTime
  field :repo, type: String
  field :service, type: String
  field :status, type: String

  def self.recent?(repo, status, service:)
    # Special Cases
    if status != 'failed' || repo == 'discourse/discourse'
      return true
    end

    if service.include?('AWDWR'.freeze)
      time_ago = 4.hours.ago
    else
      time_ago = 15.minutes.ago
    end

    if Notification.find_by(repo: repo, service: service, status: status, created_at: (time_ago..Time.now))
      true
    else
      false
    end
  end
end
