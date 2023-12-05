require "contextual_logger/version"
require "logger"

module ContextualLogger

  class LogstashLogger

    LEVEL_MAP = {
        debug: Logger::DEBUG,
        info:  Logger::INFO,
        warn:  Logger::WARN,
        error: Logger::ERROR,
        fatal: Logger::FATAL
    }

    SEVERITIES = LEVEL_MAP.keys

    InvalidLogLevel = Class.new(StandardError)

    def initialize(logstash)
      @logstash = logstash
      clear_context
    end

    def level
      @logstash.level
    end

    def add(severity, msg)
      @logstash.add(severity, msg)
    end

    def level=(value)
      level =
        case value
        when String, Symbol
          LEVEL_MAP[value.downcase.to_sym]
        when Integer
          value
        end
      LEVEL_MAP.values.include?(level) or
        raise InvalidLogLevel, "Invalid log level: #{value}"
      @logstash.level = level
    end

    def initialize_clone(other)
      super
      clear_context
    end

    SEVERITIES.each do |severity|
      define_method(severity) do |message = nil, args = {}, &block|

        args = context(severity).merge(args)

        if (ex = args[:exception]).is_a?(Exception)
          args[:exception] = "#{ex.class.name}: #{ex.message}"
        end

        if args[:source]
          level = (args[:source] == true ? 0 : args[:source].to_i)
          file, line, _ = caller[level].split(':')
          if defined?($app_config) && $app_config.app_name
            file.sub!(%r{^.*?/#{$app_config.app_name}/}, '')
          end
          args[:code_source] = [file, line].join(':')
        end

        if block && @logstash.send("#{severity}?")
          message = (message || "") << block.call
        end

        if @logstash.send("#{severity}?")
          @logstash.send severity, { message: message }.merge(args)
        end
      end

      define_method("#{severity}?") do
        @logstash.send "#{severity}?"
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
