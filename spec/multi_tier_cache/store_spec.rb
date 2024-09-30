require 'spec_helper'

RSpec.describe MultiTierCache::Store do
  let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }
  let(:redis_store) { ActiveSupport::Cache::RedisCacheStore.new(url: 'redis://localhost:6379/1') }
  let(:file_store) { ActiveSupport::Cache::FileStore.new("/tmp/cache") }

  let(:multi_store) do
    described_class.new(stores: [memory_store, redis_store, file_store])
  end

  before do
    memory_store.clear
    redis_store.clear
    file_store.clear
  end

  describe '#read' do
    it 'reads from the first store that has the value' do
      memory_store.write('key1', 'memory_value')
      redis_store.write('key2', 'redis_value')
      file_store.write('key3', 'file_value')

      expect(multi_store.read('key1')).to eq('memory_value')
      expect(multi_store.read('key2')).to eq('redis_value')
      expect(multi_store.read('key3')).to eq('file_value')
    end

    it 'populates higher priority stores when reading from lower priority stores' do
      file_store.write('key', 'file_value')

      multi_store.read('key')

      expect(memory_store.read('key')).to eq('file_value')
      expect(redis_store.read('key')).to eq('file_value')
    end
  end

  describe '#write' do
    it 'writes to all stores' do
      multi_store.write('key', 'value')

      expect(memory_store.read('key')).to eq('value')
      expect(redis_store.read('key')).to eq('value')
      expect(file_store.read('key')).to eq('value')
    end
  end

  describe '#delete' do
    it 'deletes from all stores' do
      multi_store.write('key', 'value')
      multi_store.delete('key')

      expect(memory_store.read('key')).to be_nil
      expect(redis_store.read('key')).to be_nil
      expect(file_store.read('key')).to be_nil
    end
  end

  describe '#clear' do
    it 'clears all stores' do
      multi_store.write('key1', 'value1')
      multi_store.write('key2', 'value2')
      multi_store.clear

      expect(memory_store.read('key1')).to be_nil
      expect(redis_store.read('key2')).to be_nil
      expect(file_store.read('key1')).to be_nil
    end
  end
end
