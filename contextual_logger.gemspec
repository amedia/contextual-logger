# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'contextual_logger/version'

Gem::Specification.new do |spec|
  spec.name          = "contextual_logger"
  spec.version       = ContextualLogger::VERSION
  spec.authors       = ["Lars Haugseth"]
  spec.email         = ["lars.haugseth@amedia.no"]
  spec.summary       = %q{Gem for logging with contextual info}

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "logstash-logger", "~> 0.15"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "simplecov", "~> 0.7"
  spec.add_development_dependency "simplecov-rcov", "~> 0.2"
end
