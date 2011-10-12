Gem::Specification.new do |s|
  s.name            = "redis_directory"
  s.version         = "1.0.1"
  s.platform        = Gem::Platform::RUBY
  s.summary         = "Redis Directory for retriving/storing redis connections in a central database."

  s.description = <<-EOF
Redis::Directory assumes a Redis installation running on a default
port and database 0 that will contain connection information for various
other Redis databases. For example, if you were using a Redis database to
store the content of cached pages, and this was running on a cluster of
two Redis instances, with multiple applications connecting partitioned by
database, then your connection might look like this:

  require "redis"
  require "redis/distributed"

  # The ACME Corp database is #27
  cache = Redis::Distributed.new "redis://redis.example:4400/27", "redis://redis.example:4401/27"

Redis::Directory uses a centralized Redis database to store the
connection information so you don't have to remember "magic numbers" for
each client/database mapping, and can easily update port-numbers/hostnames,
cluster-members as necessary. The same connection with
Redis::Directory would look like this:

  require "redis_directory"
  
  cache = Redis::Directory.new("redis.example").connect("cache", "acme")
EOF

  s.files           = Dir[ "README", "lib/**/*", "test/**/*", "redis_directory.gemspec", "Rakefile" ]
  s.require_path    = "lib"
  s.test_files      = Dir["test/**/*_test.rb"]

  s.author          = "Sam Smoot"
  s.email           = "ssmoot@gmail.com"
  s.homepage        = "https://github.com/wiecklabs/redis_directory"
  s.license         = "MIT"
  
  s.has_rdoc = true
  s.rdoc_options = [ "--inline-source", "--line-numbers", "--title", "Redis Directory: A database connection manager for Redis", "README", "MIT-LICENSE", "lib" ]
end