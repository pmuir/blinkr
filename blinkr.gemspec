# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blinkr/version'

Gem::Specification.new do |spec|
  spec.name          = "blinkr"
  spec.version       = Blinkr::VERSION
  spec.authors       = ["Pete Muir"]
  spec.email         = ["pmuir@bleepbleep.org.uk"]
  spec.summary       = %q{A simple broken link checker}
  spec.homepage      = ""
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.0'

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_dependency 'nokogiri', '~> 1.5'
  spec.add_dependency 'typhoeus', '~> 0.6'
  spec.add_dependency 'slim', '~> 2.0'
  spec.add_dependency 'parallel', '~> 1.0.0'
end
