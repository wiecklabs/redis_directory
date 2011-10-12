require "rake"
require "rake/clean"
require "rake/testtask"
require "rake/rdoctask"

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

CLEAN.include ["*.gem", "rdoc"]
RDOC_OPTS = [ "--quiet", "--inline-source", "--line-numbers", "--title", "Redis Directory: A database connection manager for Redis", "--main", "README" ]

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.rdoc_files.add %w"README MIT-LICENSE lib/redis_directory.rb"
end

desc "Package redis_directory"
task :package do
  sh %{gem build redis_directory.gemspec}
end