require "bundler/gem_tasks"

GEMFILE = "aweplug-#{Aweplug::VERSION}.gem"

desc "Run all tests and build the gem"
task :build => 'test:spec' do
  system "gem build aweplug.gemspec"
end

namespace :release do
  desc "Release the gem to rubygems"
  task :push => [ :build, :tag ] do
    system "gem push #{GEMFILE}"
  end

  desc "Create tag #{Aweplug::VERSION} in git"
  task :tag do
    system "git tag #{Aweplug::VERSION}"
  end
end

