web: bundle exec puma -C config/puma.rb -p $PORT
worker: bundle exec sidekiq -q default -r ./workers.rb -c 5
