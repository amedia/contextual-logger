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

Contextual info (related to the current HTTP request) can be added anywhere before the logging is performed:
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
