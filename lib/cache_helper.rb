module CacheHelper
  def self.included(base)
    base.alias_method_chain :cache_key, :new_record_id
    base.extend(ClassMethods)
  end

  # Overrides ActiveRecord::Base#cache_key to return unique keys for new
  # records.
  def cache_key_with_new_record_id
    key = cache_key_without_new_record_id
    if self.new_record?
      # The object is not yet database-backed; append the object's ID and the
      # current time to use as a provisional cache key.
      if @temp_cache_key.nil?
        @temp_cache_key = key << "(#{self.__id__})-#{Time.now.to_s(:number)}"
      else
        key = @temp_cache_key
      end
    end
    key
  end

  # Returns a cache key associated with the record for the specified method
  # and options.
  def method_cache_key(method, options = {})
    key = self.cache_key + "-#{method.to_s}"
    key << ".#{options.hash.to_s(36)}" unless options.empty?
    key
  end

  module ClassMethods
  private
    # Wraps an instance method with basic caching functionality.
    def cache_method(method)
      method_with_caching, method_without_caching = method_chain_aliases(method, :caching)
      define_method(method_with_caching.to_sym) {
        Rails.cache.fetch(method_cache_key(method)) do
          self.__send__(method_without_caching.to_sym)
        end
      }
      alias_method_chain method, :caching
    end
  end
end

class ActiveRecord::Base
  include CacheHelper
end
