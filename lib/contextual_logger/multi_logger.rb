require "contextual_logger/version"

module ContextualLogger

  class MultiLogger

    def initialize(logger = nil, logstash = nil)
      @logger   = logger
      @logstash = logstash
      clear_context
    end

    def initialize_clone(other)
      super
      clear_context
    end

    [:debug, :info, :warn, :error, :fatal].each do |severity|
      define_method(severity) do |message = nil, args = {}, &block|

        args.merge! context(severity)

        if (ex = args[:exception]).is_a?(Exception)
          args[:exception] = "#{ex.class.name}: #{ex.message}"
        end

        if args[:source]
          level = (args[:source] == true ? 0 : args[:source].to_i)
          file, line, _ = caller[level].split(':')
          if defined?($app_config) && $app_config.app_name
            file.sub!(%r{^.*?/#{$app_config.app_name}/}, '')
          end
          args[:source] = [file, line].join(':')
        end

        if block && ((@logger && @logger.send("#{severity}?") ||
            @logstash && @logstash.send("#{severity}?")))
          message = (message || "") << block.call
        end

        if @logger && @logger.send("#{severity}?")
          line = message.dup
          unless args.empty?
            line << ' {' << args.map { |k, v| "#{k}: #{v.inspect}" }.join(', ') << '}'
          end
          @logger.send severity, line
        end

        if @logstash && @logstash.send("#{severity}?")
          @logstash.send severity, { message: message }.merge(args)
        end
      end

      define_method("#{severity}?") do
        (@logger && @logger.send("#{severity}?")) ||
          (@logstash && @logstash.send("#{severity}?"))
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
