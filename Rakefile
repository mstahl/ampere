# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "ampere"
  gem.homepage = "http://github.com/mstahl/ampere"
  gem.license = "EPL"
  gem.summary = %Q{A pure Ruby ORM for Redis.}
  gem.description = %Q{An ActiveRecord/Mongoid-esque object model for the Redis key/value data store.}
  gem.email = "max@villainousindustri.es"
  gem.authors = ["Max Thom Stahl"]
  gem.post_install_message = %{Thanks for installing Ampere!}
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features)

task :default => :test

require 'rdoc/task'
# Rake::RDocTask.new do |rdoc|
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ampere #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :redis do
  desc "Flush Redis data (warning: will flush EVERYTHING, including non-Ampere stuff)"
  task :flush do
    require 'redis'
    Redis.new.flushall
    puts "Redis data FLUSHED!"
  end
end

