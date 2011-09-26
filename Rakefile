require "pathname"
require "rubygems"
require "bundler/setup"
require "rake"
require "rake/testtask"
require "rake/gempackagetask"

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

def gemspec
  @gemspec ||= begin
    file = File.expand_path("redis_connection_manager.gemspec", __FILE__)
    eval(File.read(file), binding, file)
  end
end

Rake::GemPackageTask.new(gemspec) do |package|
  package.gem_spec = gemspec
end

desc "Validate gemspec"
task :gemspec do
  gemspec.validate
end