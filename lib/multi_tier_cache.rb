# frozen_string_literal: true

require_relative "multi_tier_cache/version"
require_relative "multi_tier_cache/store"

module MultiTierCache
  class Error < StandardError; end

  class << self
    def new(memory_store: nil, redis_store: nil, memory_ttl: 5.minutes)
      Store.new(memory_store: memory_store, redis_store: redis_store, memory_ttl: memory_ttl)
    end
  end
end
