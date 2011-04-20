module CacheHelper
  def self.included(base)
    base.alias_method_chain :cache_key, :new_record_id
    base.extend(ClassMethods)
  end

  # Overrides ActiveRecord::Base#cache_key to return unique cache keys for new
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

  # Returns a cache key associated with the record for the specified method,
  # associations, and options.
  def method_cache_key_using_associations(method, *remaining_args)
    options = remaining_args.extract_options!
    associations = remaining_args
    associations.each do |association|
      options["#{association.to_s}_updated_time".to_sym] = association_updated_time(association)
    end
    method_cache_key(method, options)
  end

  # Returns the latest updated time of the record or records in the specified
  # association.  This can be used as a method_cache_key option if the method's
  # return value depends on the associated records.
  def association_updated_time(association)
    self.class.reflect_on_all_associations.each do |assoc_reflection|
      if (assoc_reflection.name == association)
        case assoc_reflection.macro
        when :has_one, :belongs_to
          return self.__send__(association).updated_at
        when :has_many, :has_and_belongs_to_many
          return self.__send__(association).maximum(:updated_at)
        end
      end
    end
    raise ArgumentError.new("association #{association.inspect} not found in #{self.class.name}")
  end

  module ClassMethods
  private
    # Adds basic caching functionality to an instance method.
    def cache_method(method)
      cache_method_using_cache_key_method(method, :method_cache_key, method)
    end

    # Adds basic caching functionality to an instance method whose return value
    # depends on associated records.
    def cache_method_using_associations(method, *associations)
      associations.each do |association|
        raise ArgumentError.new("association #{association.inspect} not found in #{self.name}") unless self.reflect_on_all_associations.any? { |assoc_reflection| assoc_reflection.name == association }
      end
      cache_method_using_cache_key_method(method, :method_cache_key_using_associations, method, *associations)
    end

    # Adds basic caching functionality to an instance method using the
    # specified cache key method and arguments.
    def cache_method_using_cache_key_method(method, cache_key_method, *cache_key_method_args)
      method_with_caching, method_without_caching = method_chain_aliases(method, :caching)
      define_method(method_with_caching.to_sym) {
        Rails.cache.fetch(self.__send__(cache_key_method, *cache_key_method_args)) do
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
