describe ContextualLogger::MultiLogger do

  let(:logger) do
    double(:logger).as_null_object
  end

  let(:logstash) do
    double(:logstash).as_null_object
  end

  let(:slow_service) do
    double(:slow_service, fetch: "returned value")
  end

  subject do
    ContextualLogger::MultiLogger.new(logger, logstash)
  end

  context "adding info to context" do
    before do
      subject[:foo] = "value"
      subject[:bar] = "other"
    end
    it "context contains the info added for all severities" do
      [:debug, :info, :warn, :error, :fatal].each do |severity|
        expect(subject.context(severity)).to include(foo: "value", bar: "other")
      end
    end
  end

  context "adding info to context with underscore-prefixed keys" do
    before do
      subject[:_foo] = "value"
      subject[:_bar] = "other"
    end
    it "context contains the info added for error severities" do
      [:error, :fatal].each do |severity|
        expect(subject.context(severity)).to include(_foo: "value", _bar: "other")
      end
    end
    it "context does not contain the info added for non-error severities" do
      [:debug, :info, :warn].each do |severity|
        expect(subject.context(severity)).not_to include(:_foo, :_bar)
      end
    end
  end

  context "logging with non-error severity" do
    before do
      subject[:foo]  = "value"
      subject[:_bar] = "other"
      subject.info "Hello World"
    end
    it "passes message and context on to logger" do
      expect(logger).to have_received(:info).with('Hello World {:foo=>"value"}')
    end
    it "passes message and context on to logstash" do
      expect(logstash).to have_received(:info).with(message: 'Hello World', foo: 'value')
    end
  end

  context "logging with error severity" do
    before do
      subject[:foo]  = "value"
      subject[:_bar] = "other"
      subject.error "Oh no!"
    end
    it "passes message and context on to logger" do
      expect(logger).to have_received(:error).
        with('Oh no! {:foo=>"value", :_bar=>"other"}')
    end
    it "passes message and context on to logstash" do
      expect(logstash).to have_received(:error).
        with(message: 'Oh no!', foo: 'value', _bar: 'other')
    end
  end

  context "logging with error severity and _exception info in context" do
    before do
      subject[:_exception] = StandardError.new("Oopsie!")
      subject.error "Oh no!"
    end
    it "passes message and exception info on to logger" do
      expect(logger).to have_received(:error).
        with('Oh no! {:_exception=>"StandardError: Oopsie!"}')
    end
    it "passes message and exception info on to logstash" do
      expect(logstash).to have_received(:error).
        with(message: 'Oh no!', _exception: "StandardError: Oopsie!")
    end
  end

  context "logging with a block" do
    before do
      subject.info { "Foobar" }
    end
    it "passes the value of the block on to logger" do
      expect(logger).to have_received(:info).
        with('Foobar')
    end
    it "passes the value of the block on to logstash" do
      expect(logstash).to have_received(:info).
        with(message: 'Foobar')
    end
  end

  context "logging with a block and severity limit below log level" do
    before do
      logger.stub(:info?) { false }
      logstash.stub(:info?) { false }
      subject.info { slow_service.fetch }
    end
    it "does not call the block" do
      expect(slow_service).not_to have_received(:fetch)
    end
    it "does not pass anything to logger" do
      expect(logger).not_to have_received(:info)
    end
    it "does not pass anything to logstash" do
      expect(logstash).not_to have_received(:info)
    end
  end
end
