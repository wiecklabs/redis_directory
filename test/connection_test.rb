require File.dirname(__FILE__) + "/helper"

class ConnectionTest < MiniTest::Unit::TestCase

  def setup
    @rcm = RedisConnectionManager.new(ENV["RCM_DICTIONARY"] || "localhost")
    
    @redis = @rcm.dictionary
    @redis.hset RedisConnectionManager::SERVICES_KEY, "cache", [ "localhost" ].to_json
    @redis.hset RedisConnectionManager::SERVICES_KEY, "sessions", [ "localhost" ].to_json
    @redis.hset RedisConnectionManager::SERVICES_KEY, "queue", [ "localhost" ].to_json
  end
  
  def teardown
    @redis.flushall
    @redis.quit
  end
  
  def test_services_are_staticly_assigned
    refute_empty @rcm.services
  end
  
  def test_services_is_a_hash_of_connection_strings
    assert_kind_of Hash, @rcm.services
  end
  
  def test_service_value_is_an_array
    assert_kind_of Array, @rcm.services["queue"]
  end
  
  def test_database_number_is_retrieved
    assert_kind_of Fixnum, @rcm.next_db("sessions")
  end
  
  def test_database_number_errors_for_service_not_exist
    assert_raises(RedisConnectionManager::UndefinedServiceError) do
      @rcm.next_db("quack")
    end
  end
  
  def test_database_contains_connection_name
    assert_equal "acme", @rcm.connect("cache", "acme").get("connection-name")
  end
  
  def test_database_is_reserved
    @rcm.reserve("cache", "acme")
    assert @redis.hexists("cache-service", "acme")
    refute_nil @redis.hget("cache-service", "acme")
  end
  
  def test_additional_cache_connection_increments
    @rcm.reserve("cache", "acme")
    @rcm.reserve("cache", "trioptimum")
    assert_equal @redis.hlen("cache-service"), @redis.hget("cache-service", "trioptimum").to_i
  end
  
  def test_sparse_ids_are_filled
    @redis.hset("cache-service", "corporatron", 5)

    @rcm.reserve("cache", "bnl")
    assert_equal 1, @redis.hget("cache-service", "bnl").to_i
    
    @rcm.reserve("cache", "axiom")
    assert_equal 2, @redis.hget("cache-service", "axiom").to_i
  end
  
  def test_database_ids_are_unbalanced
    bnl     = @rcm.reserve("cache", "bnl")
    hacker  = @rcm.reserve("cache", "trioptimum")
    acme    = @rcm.reserve("cache", "acme")

    shodan  = @rcm.reserve("sessions", "trioptimum")

    refute_equal hacker, shodan
  end
  
end