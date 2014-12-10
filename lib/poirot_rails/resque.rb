begin
  require "resque"
rescue LoadError
end

if defined?(Resque)
  module Resque
    def enqueue_to_with_poirot(queue, klass, *args)
      activity_id = PoirotRails::Activity.current.id
      link_id = Guid.new.to_s
      PoirotRails::Activity.current.logentry(:info, "Enqueue '#{klass}'", ["resque"], link_id: link_id)
      enqueue_to_without_poirot(queue, klass, activity_id, link_id, *args)
    end
    alias_method_chain :enqueue_to, :poirot
  end

  module PoirotJobWrapper
    def self.included(c)
      class << c
        def perform_with_poirot(activity_id, link_id, *args)
          PoirotRails::Activity.resume(activity_id) do
            PoirotRails::Activity.start(self.to_s, link_id: link_id, async: true) do
              perform_without_poirot(*args)
            end
          end
        end
        alias_method_chain :perform, :poirot
      end
    end
  end

  class Resque::Job
    def perform_with_poirot
      unless payload_class.include?(PoirotJobWrapper)
        payload_class.include(PoirotJobWrapper)
      end
      perform_without_poirot
    end
    alias_method_chain :perform, :poirot
  end

end
