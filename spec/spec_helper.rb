$:.unshift(File.dirname(File.dirname(__FILE__)))

# Code coverage only when requested
if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-rcov'
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.add_filter 'spec'
  SimpleCov.add_filter 'config'
  SimpleCov.start
end

require 'contextual_logger/multi_logger'
