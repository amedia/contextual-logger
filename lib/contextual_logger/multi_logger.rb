require "contextual_logger/version"

module ContextualLogger

  class MultiLogger

    def initialize(logger = nil, logstash = nil)
      @logger   = logger
      @logstash = logstash
      clear_context
    end

    [:debug, :info, :warn, :error, :fatal].each do |severity|
      define_method(severity) do |message = nil, args = {}, &block|

        args.merge! context(severity)

        if (ex = args[:exception]).is_a?(Exception)
          args[:exception] = "#{ex.class.name}: #{ex.message}"
        end

        if block && ((@logger && @logger.send("#{severity}?") ||
            @logstash && @logstash.send("#{severity}?")))
          message = (message || "") << block.call
        end

        if @logger && @logger.send("#{severity}?")
          line = message.dup
          line << " " << args.inspect unless args.empty?
          @logger.send severity, line
        end

        if @logstash && @logstash.send("#{severity}?")
          @logstash.send severity, { message: message }.merge(args)
        end
      end
    end

    def clear_context
      @context = {}
      @error_context = {}
    end

    def add_context(hash)
      @context.merge! hash
    end

    def add_error_context(hash)
      @error_context.merge! hash
    end

    def context(severity)
      case severity
      when :error, :fatal
        @context.merge(@error_context)
      else
        @context
      end
    end
  end
end
