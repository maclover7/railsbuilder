require 'sidekiq'
require_relative 'app.rb'

class BookNotificationWorker
  include Sidekiq::Worker

  def perform(info)
    repo = [info['rails'], info['ruby']].join('-')
    if info['pass'] == true
      status = 'passing'
    else
      status = 'failed'
    end

    unless Notification.recent?(repo, status, service: 'AWDWR')
      #notify_campfire
      Notification.create(repo: repo, service: 'AWDWR', status: status, created_at: Time.now)
      puts "Notification created at #{Time.now} for #{repo} (AWDWR)"
    end
  end
end

class TravisNotificationWorker
  include Sidekiq::Worker

  def perform(repo, status)
    unless Notification.recent?(repo, status, service: 'travis')
      #notify_campfire
      Notification.create(repo: repo, service: 'travis', status: status, created_at: Time.now)
      puts "Notification created at #{Time.now} for #{repo} (Travis)"
    end
  end
end
