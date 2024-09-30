require 'active_support'
require 'active_support/cache'

module MultiTierCache
  class Store < ActiveSupport::Cache::Store
    def initialize(options = {})
      @stores = options[:stores] || []
      super(options)
    end

    def read(name, options = nil)
      @stores.each do |store|
        value = store.read(name, options)
        if value
          # Write to all higher priority stores
          @stores.each do |higher_store|
            break if higher_store == store
            higher_store.write(name, value, options)
          end
          return value
        end
      end
      nil
    end

    def write(name, value, options = nil)
      @stores.each { |store| store.write(name, value, options) }
    end

    def delete(name, options = nil)
      @stores.each { |store| store.delete(name, options) }
    end

    def clear(options = nil)
      @stores.each { |store| store.clear(options) }
    end
  end
end
