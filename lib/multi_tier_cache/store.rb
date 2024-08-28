require 'active_support/cache'

module MultiTierCache
  class Store < ActiveSupport::Cache::Store
    def initialize(memory_store: nil, redis_store: nil, memory_ttl: 5.minutes)
      @memory_store = memory_store || ActiveSupport::Cache::MemoryStore.new
      @redis_store = redis_store || ActiveSupport::Cache::RedisCacheStore.new
      @memory_ttl = memory_ttl
    end

    def read(name, options = nil)
      value = @memory_store.read(name, options)
      if value
        return value
      else
        value = @redis_store.read(name, options)
        if value
          # Cache in memory for faster subsequent reads
          @memory_store.write(name, value, expires_in: @memory_ttl)
        end
        return value
      end
    end

    def write(name, value, options = nil)
      memory_options = options ? options.dup : {}
      memory_options[:expires_in] = @memory_ttl

      @memory_store.write(name, value, memory_options)
      @redis_store.write(name, value, options)
    end

    def delete(name, options = nil)
      @memory_store.delete(name, options)
      @redis_store.delete(name, options)
    end

    def clear
      @memory_store.clear
      @redis_store.clear
    end

    def increment(name, amount = 1, options = nil)
      result = @redis_store.increment(name, amount, options)
      @memory_store.write(name, result, expires_in: @memory_ttl)
      result
    end

    def decrement(name, amount = 1, options = nil)
      result = @redis_store.decrement(name, amount, options)
      @memory_store.write(name, result, expires_in: @memory_ttl)
      result
    end
  end
end

# lib/multi_tier_cache.rb
require "multi_tier_cache/store"

module MultiTierCache
  class << self
    def new(memory_store: nil, redis_store: nil, memory_ttl: 5.minutes)
      Store.new(memory_store: memory_store, redis_store: redis_store, memory_ttl: memory_ttl)
    end
  end
end

# Example usage in Rails (config/environments/production.rb)
# Rails.application.config.cache_store = MultiTierCache.new(
#   memory_store: ActiveSupport::Cache::MemoryStore.new(size: 64.megabytes),
#   redis_store: ActiveSupport::Cache::RedisCacheStore.new(url: ENV['REDIS_URL']),
#   memory_ttl: 10.minutes
# )
