require 'sunspot'
require 'sunspot/rails'

module Sunspot
  module Mongo
    def self.included(base)
      base.class_eval do
        extend Sunspot::Rails::Searchable::ActsAsMethods
        class << self
          def searchable_with_reindex_options(options = {}, &block)
            searchable_without_reindex_options(options, &block)
            before_save :update_auto_indexing_for_observed_attributes
          end
          alias_method_chain :searchable, :reindex_options

          def solr_reindex
            self.all.each {|a| a.indexable? ? a.index : a.remove_from_index }
            Sunspot.commit
          end
        end
        Sunspot::Adapters::DataAccessor.register(DataAccessor, base)
        Sunspot::Adapters::InstanceAdapter.register(InstanceAdapter, base)

        def update_auto_indexing_for_observed_attributes
          @marked_for_auto_indexing and
            observe_attributes = self.class.sunspot_options[:observe_attribute_changes_of] and
            @marked_for_auto_indexing = !(changed & observe_attributes.collect(&:to_s)).empty?
          true
        end
      end
    end

    class InstanceAdapter < Sunspot::Adapters::InstanceAdapter
      def id
        @instance.id
      end
    end

    class DataAccessor < Sunspot::Adapters::DataAccessor
      def load(id)
        @clazz.find(id)
      end

      def load_all(ids)
        @clazz.find(ids)
      end
    end
  end
end
