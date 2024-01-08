# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads "8", "32"

unless ENV['RAILS_ENV'] == 'development'
  bind 'unix:///var/run/puma/my_app.sock'
  stdout_redirect '/var/log/puma/puma.log', '/var/log/puma/puma.log', true
end

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
rackup         DefaultRackup
port           ENV.fetch("PORT") { 3000 }
environment    ENV.fetch("RAILS_ENV") { "development" }
worker_timeout 3600

# Specifies the `pidfile` that Puma will use.
# pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers %x(grep -c processor /proc/cpuinfo)

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
  # if defined?(Resque)
  #    Resque.redis = ENV["<redis-uri>"] || "redis://127.0.0.1:6379"
  # end
end
# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
