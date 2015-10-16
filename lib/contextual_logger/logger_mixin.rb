require "contextual_logger/version"

# This code assumes that LOGGER is set up as a ContextualLogger instance. :-)
module ContextualLogger
  module LoggerMixin
    def logger
      @logger ||= LOGGER.clone # Use clone to get empty context
      logger.add_context pid: $$, source: true
    end
  end
end

