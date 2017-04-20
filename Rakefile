require 'bundler/gem_tasks'
require 'rake/testtask'

GEMFILE = "blinkr-#{Blinkr::VERSION}.gem".freeze

desc 'Run all unit-tests'
task :test do |args|
  Rake::Task[:unit_test_task].invoke(args)
end

Rake::TestTask.new do |t|
  t.name = :unit_test_task
  t.warning = false
  t.verbose = true
  t.test_files = FileList['test/unit-test/*.rb', 'test/unit-test/extensions/*.rb']
end

desc 'Build the gem'
task :build do
  system 'gem build blinkr.gemspec'
end

namespace :release do
  desc 'Release the gem to rubygems'
  task push: %I[build tag] do
    system "gem push #{GEMFILE}"
  end

  desc "Create tag #{Blinkr::VERSION} in git"
  task :tag do
    system "git tag #{Blinkr::VERSION}"
  end
end
