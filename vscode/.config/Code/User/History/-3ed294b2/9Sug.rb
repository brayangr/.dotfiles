Rollbar.configure do |config|
  # Without configuration, Rollbar is enabled in all environments.
  # To disable in specific environments, set config.enabled=false.

  config.access_token = ENV['ROLLBAR']

  # # Here we'll disable in 'test' and 'development'':
  # if Rails.env.test? || Rails.env.development?
  #   config.enabled = false
  # end

  config.before_process << lambda do |options|
    conditions_to_filter = options[:exception] &&
                           !options[:exception].message.include?(Constants::Rollbar::FILTERED_TEXT) &&
                           Constants::Rollbar::MESSAGES_TO_FILTER.any? { |word| options[:exception].message.include?(word) }

    if conditions_to_filter
      original_exception = options[:exception]
      scrubed_message = scrub_url!(options[:exception].message.dup)
      scrubed_exception = original_exception.class.new(scrubed_message)
      scrubed_exception.set_backtrace(original_exception.backtrace)
      Rollbar.error(scrubed_exception.message, backtrace: scrubed_exception.backtrace)

      raise Rollbar::Ignore
    end

    true
  end

  # By default, Rollbar will try to call the `current_user` controller method
  # to fetch the logged-in user object, and then call that object's `id`,
  # `username`, and `email` methods to fetch those properties. To customize:
  # config.person_method = "my_current_user"
  # config.person_id_method = "my_id"
  # config.person_username_method = "my_username"
  # config.person_email_method = "my_email"

  # If you want to attach custom data to all exception and message reports,
  # provide a lambda like the following. It should return a hash.
  # config.custom_data_method = lambda { {:some_key => "some_value" } }

  # Add exception class names to the exception_level_filters hash to
  # change the level that exception is reported at. Note that if an exception
  # has already been reported and logged the level will need to be changed
  # via the rollbar interface.
  # Valid levels: 'critical', 'error', 'warning', 'info', 'debug', 'ignore'
  # 'ignore' will cause the exception to not be reported at all.
  # config.exception_level_filters.merge!('MyCriticalException' => 'critical')
  #
  # You can also specify a callable, which will be called with the exception instance.
  # config.exception_level_filters.merge!('MyCriticalException' => lambda { |e| 'critical' })

  # Enable asynchronous reporting (uses girl_friday or Threading if girl_friday
  # is not installed)
  config.use_async = true
  # Supply your own async handler:
  config.async_handler = Proc.new { |payload|
    Thread.new { Rollbar.process_from_async_handler(payload) }
  }

  ######################################################
  # Scrub sensitive data that is configured for not being logged.
  # When you add additional filtered fields to `filter_parameter_logging.rb`,
  # those will automatically be picked up by this.
  config.scrub_headers |= Rails.application.config.filter_parameters.map(&:to_s)
  config.scrub_fields |= Rails.application.config.filter_parameters.map(&:to_s)


  config.transform << proc do |options|
    data = options[:payload]['data']
    data[:cookies] = Rollbar::Scrubbers.scrub_value(data[:cookies])
    data[:request][:user_ip] = Rollbar::Scrubbers.scrub_value(data[:request][:user_ip])

    # This code is to handle Timeout errors as separate items
    if (body = options[:payload]['data'][:body]) && (trace = body[:trace] || body[:trace_chain])
      exception = trace[:exception]
      if exception[:class] == 'Errors::Custom::RackTimeout'
        options[:payload]['data'][:fingerprint] = trace[:extra][:controller_info]
      end
    end
  end

  # Enable asynchronous reporting (using sucker_punch)
  # config.use_sucker_punch

  # Enable delayed reporting (using Sidekiq)
  # config.use_sidekiq
  # You can supply custom Sidekiq options:
  # config.use_sidekiq 'queue' => 'default'

  # If you run your staging application instance in production environment then
  # you'll want to override the environment reported by `Rails.env` with an
  # environment variable like this: `ROLLBAR_ENV=staging`. This is a recommended
  # setup for Heroku. See:
  # https://devcenter.heroku.com/articles/deploying-to-a-custom-rails-environment
  config.environment = ENV['ROLLBAR_ENV'] || Rails.env
end

def scrub_url!(message)
  Rails.application.config.filter_parameters.map(&:to_s).each do |key|
    # Escaping key to safely use in regex
    escaped_key = Regexp.escape(key.to_s)
    # Regex to match the key and value in the URL
    regex = /#{escaped_key}=[^&]*&?/
    # Replacing the key and value with [FILTERED]
    message.gsub!(regex, "#{key}=#{Constants::Rollbar::FILTERED_TEXT}&")
  end
  message
end
