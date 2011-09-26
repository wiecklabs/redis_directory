Gem::Specification.new do |s|
  s.name            = "redis_connection_manager"
  s.version         = "0.1"
  s.platform        = Gem::Platform::RUBY
  s.summary         = "Redis connection manager for retriving/storing redis connections in a central database."

  s.description = <<-EOF
RedisConnectionManager assumes a Redis installation running on a default
port and database 0 that will contain connection information for various
other Redis databases. For example, if you were using a Redis database to
store the content of cached pages, and this was running on a cluster of
two Redis instances, with multiple applications connecting partitioned by
database, then your connection might look like this:

  require "redis"
  require "redis/distributed"

  # The ACME Corp database is #27
  cache = Redis::Distributed.new "redis://redis.example:4400/27", "redis://redis.example:4401/27"

RedisConnectionManager using a centralized Redis database to store the
connection information so you don't have to remember "magic numbers" for
each client/database mapping, and can easily update port-numbers/hostnames,
cluster-members as necessary. The same connection with
RedisConnectionManager would look like this:

  require "redis_connection_manager"
  
  cache = RedisConnectionManager.new("redis.example").connect("cache", "acme")
EOF

  s.files           = Dir[ "lib/**/*", "test/**/*", "redis_connection_manager.gemspec", "Rakefile" ]
  s.require_path    = "lib"
  s.test_files      = Dir["test/**/*_test.rb"]

  s.author          = "Sam Smoot"
  s.email           = "ssmoot@gmail.com"
end
