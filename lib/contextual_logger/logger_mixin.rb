require "contextual_logger/version"

# This code assumes that LOGGER is set up as a ContextualLogger instance. :-)
module ContextualLogger
  module LoggerMixin
    def logger
      # Use clone to get empty context
      @logger ||= (defined?(LOGGER) && LOGGER.clone) or
        raise 'To use LoggerMixin, LOGGER needs to be set up.'
      @logger.add_context pid: $$, source: true
      if $app_config
        @logger.add_context application: $app_config.app_name
      end
      @logger
    end
  end
end

