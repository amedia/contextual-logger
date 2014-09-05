require "contextual_logger/version"

module ContextualLogger

  class MultiLogger

    def initialize(logger = nil, logstash = nil)
      @logger     = logger
      @logstash   = logstash
      @context    = {}
      @errcontext = {}
    end

    [:debug, :info, :warn, :error, :fatal].each do |severity|
      define_method(severity) do |message = nil, args = {}, &block|

        args.merge! context(severity)

        if (ex = args[:_exception]).is_a?(Exception)
          args[:_exception] = "#{ex.class.name}: #{ex.message}"
        end

        if (@logger && @logger.send("#{severity}?") ||
            @logstash && @logstash.send("#{severity}?"))
          message = (message || "") << block.call if block
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

    def []=(key, value)
      if key.to_s[0] == '_'
        @errcontext[key] = value
      else
        @context[key] = value
      end
    end

    def context(severity)
      case severity
      when :error, :fatal
        @context.merge(@errcontext)
      else
        @context
      end
    end
  end
end
