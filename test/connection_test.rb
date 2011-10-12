require File.dirname(__FILE__) + "/helper"

class ConnectionTest < MiniTest::Unit::TestCase

  def setup
    @directory = Redis::Directory.new(:host => (ENV["REDIS_DIRECTORY"] || "localhost"))
    
    @redis = @directory.redis
    @redis.hset Redis::Directory::SERVICES_KEY, "cache", [ "localhost" ].to_json
    @redis.hset Redis::Directory::SERVICES_KEY, "sessions", [ "localhost" ].to_json
    @redis.hset Redis::Directory::SERVICES_KEY, "queue", [ "localhost" ].to_json
  end
  
  def teardown
    @redis.flushall
    @redis.quit
  end
  
  # Our first test verifies that the "services" key (populated here in #setup) is not empty.
  # Since we can't know the hostname(s) and ports for the Redis members you've setup, you
  # must pre-populate this.
  # This can be as easy as using the redis-cli on the command-line to populate your directory:
  #
  #   redis-cli -h redis.example.com -p 8440 hset services cache '["redis.example.com:9100", "redis.example.com:9101"]'
  #   redis-cli -h redis.example.com -p 8440 hset services sessions '["redis.example.com:9200", "redis.example.com:9201"]'
  #   redis-cli -h redis.example.com -p 8440 hset services queue '["redis.example.com:9300"]'
  #
  # Then +@directory.services+ would be equal to:
  #
  #   {
  #     "cache"     => ["redis.example.com:9100", "redis.example.com:9101"],
  #     "sessions"  => ["redis.example.com:9200", "redis.example.com:9201"],
  #     "queue"     => ["redis.example.com:9300"]
  #   }
  # 
  # These are the definitions for your cluster(s) of services.
  # It's recommended that you dedicate individual use-cases to individual clusters.
  # This helps you balance your loads more evenly across multi-core machines
  # (since Redis is single-threaded) as well as allowing you to tune memory limits,
  # flush-to-disk intervals, etc on a per-cluster basis.
  def test_services_are_staticly_assigned
    refute_empty @directory.services
  end
  
  def test_services_is_a_hash_of_connection_strings
    assert_kind_of Hash, @directory.services
  end
  
  # Because we use a Redis::Distributed connection, you should consistently
  # use Arrays for your cluster connections even if there is only one item
  # in the cluster.
  def test_service_value_is_an_array
    assert_kind_of Array, @directory.services["queue"]
  end
  
  # Here we're just confirming that when we ask for it, the next availble
  # database number for a given service is retrieved.
  def test_database_number_is_retrieved
    assert_kind_of Fixnum, @directory.next_db("sessions")
  end
  
  # If the service/cluster is undefined, then we should raise a
  # UndefinedServiceError when requesting it's next database number.
  def test_database_number_errors_for_service_not_exist
    assert_raises(Redis::Directory::UndefinedServiceError) do
      @directory.next_db("quack")
    end
  end
  
  # Once we've made a connection (+Redis::Directory#get+), we should be able
  # to confirm that the database we've connected to is for this name.
  def test_database_contains_connection_name
    assert_equal "acme", @directory.get("cache", "acme").get("connection-name")
  end
  
  # If we reserve a database, it should be tracked in a Hash describing the
  # currently reserved services for that name. That way we can look it up later
  # and re-use it instead of always provisioning new databases every time you
  # make a new request.
  def test_database_is_reserved
    @directory.reserve("cache", "acme")
    assert @redis.hexists("cache-service", "acme")
    refute_nil @redis.hget("cache-service", "acme")
  end
  
  # This test confirms an internal implementation detail, ensuring that we don't
  # have collisions between multiple database names for a given service.
  def test_additional_cache_connection_increments
    @directory.reserve("cache", "acme")
    @directory.reserve("cache", "trioptimum")
    assert_equal @redis.hlen("cache-service"), @redis.hget("cache-service", "trioptimum").to_i
  end
  
  # When there are "gaps" in the list of tracked databases for a service, those
  # should be filled to keep the maximum database number as low as possible.
  # This way as long as you clean up disused databases by removing them from the
  # service keys, eg:
  #
  #   redis-cli hdel cache-service acme
  #
  # Then we'll re-use that database number, meaning that as long as you've set
  # (in your redis.conf) your maximum databases equal to or great than the number
  # you plan to use, +Redis::Directory+ should not exceed that number.
  def test_sparse_ids_are_filled
    @redis.hset("cache-service", "corporatron", 5)

    @directory.reserve("cache", "bnl")
    assert_equal 1, @redis.hget("cache-service", "bnl").to_i
    
    @directory.reserve("cache", "axiom")
    assert_equal 2, @redis.hget("cache-service", "axiom").to_i
  end
  
  # In order to use as few database numbers as possible, and again, allowing you
  # to tune Redis configuration settings like +databases+ on a per service/cluster
  # basis, database numbers may not be consistent across services/clusters for a
  # given client/name. This is especially true if not all clients consume all services,
  # as the example below demonstrates.
  def test_database_ids_are_unbalanced
    bnl     = @directory.reserve("cache", "bnl")
    hacker  = @directory.reserve("cache", "trioptimum")
    acme    = @directory.reserve("cache", "acme")

    shodan  = @directory.reserve("sessions", "trioptimum")

    refute_equal hacker, shodan
  end
  
end