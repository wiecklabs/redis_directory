require "redis"
require "redis/distributed"
require "json"

class Redis::Directory
  
  SERVICES_KEY = "services"
  DATABASES_KEY = "databases"
  
  # Hard-coded, because I don't know how to get this from the Redis connection at runtime.
  MAXIMUM_DATABASE_COUNT = 65535
  
  # This error is thrown when you request a service that is not defined in the directory's "services" key.
  class UndefinedServiceError < StandardError
    def initialize(directory, service_name)
      super "#{service_name} is not an available service! (#{directory.services.keys.sort})"
    end
  end
  
  # If you are unable to reserve a database during a connection attempt, this error is raised.
  class ReservationError < StandardError
    def initialize(directory, service_name, connection_name)
      super "Unable to reserve a database for #{service_name}:#{connection_name}!\nCurrent databases for service: #{directory.redis.hgetall("#{service_name}-service")}"
    end
  end
  
  # You must provide the +connection_string+ to the directory server.
  def initialize(connection_string)
    @redis = Redis.new(connection_string)
  end
  
  def services
    if redis.exists(SERVICES_KEY)
      redis.hgetall(SERVICES_KEY).inject({}) do |h,(k,v)|
        h[k] = JSON.parse(v); h
      end
    else
      {}
    end
  end
  
  # This locates the next available database for a given service, starting at an index of 1.
  # The 0 database is reserved in case you have a default connection, or local redis server
  # (in which case 0 should be the directory database to avoid conflicts).
  def next_db(service_name)
    raise UndefinedServiceError.new(self, service_name) unless services.keys.include?(service_name)
    databases = redis.hvals("#{service_name}-service").map { |i| i.to_i }.sort
    (1..MAXIMUM_DATABASE_COUNT).select { |i| break i unless databases.include? i }
  end
  
  def reserve(service_name, connection_name)
    new_db = nil
    # redis.multi do
      new_db = next_db(service_name)
      redis.hset("#{service_name}-service", connection_name, new_db)
    # end
    new_db
  end
  
  def get(service_name, connection_name)
    db = reserve(service_name, connection_name)
    raise ReservationError.new(self, service_name, connection_name) if db.nil?
    connection = Redis::Distributed.new(services[service_name].map { |server| "redis://#{server}/#{db}" })
    connection.set("connection-name", connection_name)
    connection
  end
  
  def redis
    @redis
  end
end