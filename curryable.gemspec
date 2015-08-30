# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'curryable/version'

Gem::Specification.new do |spec|
  spec.name          = "curryable"
  spec.version       = Curryable::VERSION
  spec.authors       = ["Stephen Best", "Dominic Baggott"]
  spec.email         = ["bestie@gmail.com", "dominic.baggott@gmail.com"]

  spec.summary       = %q{Enables immutable command objects to act as currable functions}
  spec.homepage      = "https://github.com/evilstreak/curryable"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry", "0.10.1"
  spec.add_development_dependency "rspec"
end
