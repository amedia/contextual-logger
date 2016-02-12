---
Team: aID
Stack: Ruby

---
<!--(Maintained Duplo labels above. Read more on http://info.api.no/handbook/guidelines/GitHub-guidelines.html)-->

<!--(Maintained Duplo labels above. Read more on http://info.api.no/handbook/guidelines/GitHub-guidelines.html)-->

# ContextualLogger

This gem provides a wrapper for logging with contextual information.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'contextual_logger'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install contextual_logger

## Usage

The MultiLogger class wraps logging to both a standard Logger instance
and a LogstashLogger instance at the same time. Both logger instances
must be setup independently in advance.

For each example below, the output being logged to each instance will be
shown underneath the code example.

```ruby
FILELOGGER = Logger.new(...)
LOGSTASH   = LogStashLogger.new(...)

logger = ContextualLogger::MultiLogger.new(FILELOGGER, LOGSTASH)

logger.info "Hello, world!"
# => "Hello, world!"
# => {"message": "Hello, world!"}
```

Contextual info can be added anywhere before the logging is performed:
```ruby
logger.add_context user_id: user.id

logger.info "User logged in."
# => "User logged in. {:user_id=>123}"
# => {"message": "User logged in.", "user_id": 123}
```

Contextual info can also be tacked on directly when logging:
```ruby
logger.info "Logged out.", user_id: user.id
# => "Logged out. {:user_id=>123}"
# => {"message": "Logged out.", "user_id": 123}
```

Info added to the _error context_ will only be appended to log events
with severities of `error` or `fatal`:
```ruby
logger.add_error_context request_url: request.request_url

logger.info "Starting."
# => "Starting."
# => {"message": "Starting."}

logger.error "Failed!"
# => "Failed! {:request_url=>'http://localhost:9292/foo/bar'}
# => {"message": "Failed!", "request_url": "http://localhost:9292/foo/bar"}
```

The context can be emptied by request:
```ruby
logger.clear_context
```

Exception objects can be added to the context and will be automatically formatted:
```ruby
begin
  raise SomeError, "Oops!"
rescue SomeError => err
  logger.error "Failed.", exception: err
end
# => "Failed. {exception: "SomeError: Oops!"}
# => {"message": "Failed.", exception: "SomeError: Oops!"}
```

## LoggerMixin
To get a clean `logger` object with some common context in your code, you can
include LoggerMixin. Example:
```
class GenderGuesser
  include ContextualLogger::LoggerMixin

  def guess(name)
    # ...
    logger.info "#{name} is probably #{gender}", name: name
    # ...
  pass
end
```

Please note that this requires that you have setup contextual logger to the
global `LOGGER` variable.
