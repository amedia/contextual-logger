describe ContextualLogger::LogstashLogger do

  let(:logstash) do
    spy(:logstash)
  end

  let(:slow_service) do
    double(:slow_service, fetch: "returned value")
  end

  subject do
    ContextualLogger::LogstashLogger.new(logstash)
  end

  context "#level=" do
    it "accepts string values" do
      subject.level = 'DEBUG'
      expect(logstash).to have_received(:level=).with(Logger::DEBUG)
      subject.level = 'warn'
      expect(logstash).to have_received(:level=).with(Logger::WARN)
    end
    it "accepts symbolic values" do
      subject.level = :info
      expect(logstash).to have_received(:level=).with(Logger::INFO)
      subject.level = :FATAL
      expect(logstash).to have_received(:level=).with(Logger::FATAL)
    end
    it "accepts integer values" do
      subject.level = Logger::WARN
      expect(logstash).to have_received(:level=).with(Logger::WARN)
    end
    it "raises InvalidLogLevel for bad values" do
      ['FOO', :bar, 1234, 3.14].each do |bad_value|
        expect { subject.level = bad_value }.to raise_error(ContextualLogger::LogstashLogger::InvalidLogLevel)
      end
    end
  end

  context "#add_context" do
    before do
      subject.add_context foo: "value", bar: "other"
    end
    it "adds info to the context that is visible for all severities" do
      [:debug, :info, :warn, :error, :fatal].each do |severity|
        expect(subject.context(severity)).to include(foo: "value", bar: "other")
      end
    end
  end

  context "#add_error_context" do
    before do
      subject.add_error_context foo: "value"
      subject.add_error_context bar: "other"
    end
    it "adds info to the context that is visible for error severities" do
      [:error, :fatal].each do |severity|
        expect(subject.context(severity)).to include(foo: "value", bar: "other")
      end
    end
    it "adds info to the context that is not visible for non-error severities" do
      [:debug, :info, :warn].each do |severity|
        expect(subject.context(severity)).not_to include(:foo, :bar)
      end
    end
  end

  context "#clear_context" do
    before do
      subject.add_context foo: "value", bar: "other"
      subject.add_error_context baz: "value", quux: "other"
      subject.clear_context
    end
    it "removes all existing context" do
      [:info, :error].each do |severity|
        expect(subject.context(severity)).to be_empty
      end
    end
  end

  context "logging with non-error severity" do
    before do
      subject.add_context foo: "value"
      subject.add_error_context bar: "other"
      subject.info "Hello World"
    end
    it "passes message and context on to logstash" do
      expect(logstash).to have_received(:info).with(message: 'Hello World', foo: 'value').once
    end
  end

  context "logging with error severity" do
    before do
      subject.add_context foo: "value"
      subject.add_error_context bar: "other"
      subject.error "Oh no!"
    end
    it "passes message, context and error context on to logstash" do
      expect(logstash).to have_received(:error).
        with(message: 'Oh no!', foo: 'value', bar: 'other').once
    end
  end

  context "logging with error severity and exception info in context" do
    before do
      subject.add_error_context exception: StandardError.new("Oopsie!")
      subject.error "Oh no!"
    end
    it "passes message and exception info on to logstash" do
      expect(logstash).to have_received(:error).
        with(message: 'Oh no!', exception: "StandardError: Oopsie!").once
    end
  end

  context "logging with source requested in context with value true" do
    before do
      subject.add_context source: true
      subject.info "Yo!"
    end
    it "passes message and source info on to logstash" do
      expect(logstash).to have_received(:info).
        with(message: 'Yo!', source: true, code_source: /#{__FILE__}:#{__LINE__ - 4}/).once
    end
  end

  context "logging with source requested in context with value zero" do
    before do
      subject.add_context source: 0
      subject.info "Yo!"
    end
    it "passes message and source info on to logstash" do
      expect(logstash).to have_received(:info).
        with(message: 'Yo!', source: 0, code_source: /#{__FILE__}:#{__LINE__ - 4}/).once
    end
  end

  context "logging with source requested in context with call stack level" do
    before do
      subject.add_context source: 1
      def do_some_logging
        subject.info "Hiya"
      end
      do_some_logging
    end
    it "passes message and source info at the requested level on to logstash" do
      expect(logstash).to have_received(:info).
        with(message: 'Hiya', source: 1, code_source: /#{__FILE__}:#{__LINE__ - 4}/).once
    end
  end

  context "logging with source requested in context and $app_config.app_name set" do
    let(:app_config) { double(:app_config, app_name: 'contextual-logger') }
    before do
      $app_config = app_config
      subject.add_context source: 0
      subject.info "Yo!"
      $app_config = nil
    end
    it "passes message and source info on to logger, app directory truncated" do
      expect(logstash).to have_received(:info).
        with(message: 'Yo!', source: 0, code_source: /spec\/lib\/contextual_logger\/logstash_logger_spec.rb:#{__LINE__ - 5}/).once
    end
  end

  context "logging with additional argument hash" do
    before do
      subject.add_context foo: 42, bar: "Hey"
      subject.info "Hello", bar: "Bar", baz: "Yo"
    end
    it "passes additional arguments on to logstash, overriding context" do
      expect(logstash).to have_received(:info).with(message: 'Hello', foo: 42, bar: 'Bar', baz: 'Yo').once
    end
  end
  
  context "logging with a block" do
    before do
      subject.info { "Foobar" }
    end
    it "passes the value of the block on to logstash" do
      expect(logstash).to have_received(:info).
        with(message: 'Foobar').once
    end
  end

  context "logging with a block and the severity level is disabled" do
    let(:logger)   { spy(:logger,   :info? => false) }
    let(:logstash) { spy(:logstash, :info? => false) }
    before do
      subject.info { slow_service.fetch }
    end
    it "does not call the block" do
      expect(slow_service).not_to have_received(:fetch)
    end
    it "does not pass anything to logstash" do
      expect(logstash).not_to have_received(:info)
    end
  end
end
