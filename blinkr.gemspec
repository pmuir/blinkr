# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blinkr/version'

Gem::Specification.new do |spec|
  spec.name = 'blinkr'
  spec.version = Blinkr::VERSION
  spec.authors = ['Pete Muir', 'Jason Porter']
  spec.email = %w[pmuir@bleepbleep.org.uk lightguard.jp@gmail.com]
  spec.summary = 'A simple broken link checker'
  spec.description = <<-EOF
       A broken page and link checker for websites. Optionally uses phantomjs to render pages to check resource loading,
       links created by JS, and report any JS page load errors.
  EOF
  spec.homepage = 'https://github.com/pmuir/blinkr'
  spec.license = 'Apache-2.0'

  spec.files = `git ls-files`.split($RS)
  spec.files -= %w[.gitignore .ruby-version .ruby-gemset]

  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 1.9'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_dependency 'nokogiri', '~> 1.7.2'
  spec.add_dependency 'typhoeus', '~> 1.1.2'
  spec.add_dependency 'slim', '~> 3.0.8'
  spec.add_dependency 'parallel', '~> 1.11.2'
  spec.add_development_dependency 'rspec'
  spec.add_runtime_dependency('colorize')
  spec.add_development_dependency 'fakeweb', ['~> 1.3']

  if defined? JRUBY_VERSION
    spec.platform = 'java'
    spec.add_dependency 'manticore', '~> 0.6.1'
  end
end
