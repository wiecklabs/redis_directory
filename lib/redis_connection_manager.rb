require "redis"
require "redis/distributed"
require "json"

class RedisConnectionManager
  
  SERVICES_KEY = "services"
  DATABASES_KEY = "databases"
  MAXIMUM_DATABASE_COUNT = 65535
  
  class UndefinedServiceError < StandardError
    def initialize(manager, service_name)
      super "#{service_name} is not an available service! (#{manager.services.keys.sort})"
    end
  end
  
  class ReservationError < StandardError
    def initialize(manager, service_name, connection_name)
      super "Unable to reserve a database for #{service_name}:#{connection_name}!\nCurrent databases for service: #{manager.dictionary.hgetall("#{service_name}-service")}"
    end
  end
  
  def initialize(dictionary_connection_string)
    @dictionary = Redis.new(dictionary_connection_string)
    @connections = []
  end
  
  def services
    if dictionary.exists(SERVICES_KEY)
      dictionary.hgetall(SERVICES_KEY).inject({}) do |h,(k,v)|
        h[k] = JSON.parse(v); h
      end
    else
      {}
    end
  end
  
  def next_db(service_name)
    raise UndefinedServiceError.new(self, service_name) unless services.keys.include?(service_name)
    databases = dictionary.hvals("#{service_name}-service").map { |i| i.to_i }.sort
    (1..MAXIMUM_DATABASE_COUNT).select { |i| break i unless databases.include? i }
  end
  
  def reserve(service_name, connection_name)
    new_db = nil
    # dictionary.multi do
      new_db = next_db(service_name)
      dictionary.hset("#{service_name}-service", connection_name, new_db)
    # end
    new_db
  end
  
  def connect(service_name, connection_name)
    db = reserve(service_name, connection_name)
    raise ReservationError.new(self, service_name, connection_name) if db.nil?
    connection = Redis::Distributed.new(services[service_name].map { |server| "#{server}/#{db}" })
    @connections << connection
    connection.set("connection-name", connection_name)
    connection
  end
  
  def connections
    @connections
  end
  
  def dictionary
    @dictionary
  end
end