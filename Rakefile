require "bundler/gem_tasks"

GEMFILE = "blinkr-#{Blinkr::VERSION}.gem"

desc "Run all tests and build the gem"
task :build do
  system "gem build blinkr.gemspec"
end

namespace :release do
  desc "Release the gem to rubygems"
  task :push => [ :build, :tag ] do
    system "gem push #{GEMFILE}"
  end

  desc "Create tag #{Blinkr::VERSION} in git"
  task :tag do
    system "git tag #{Blinkr::VERSION}"
  end
end

