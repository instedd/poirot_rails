begin
  require "resque"
rescue LoadError
end

if defined?(Resque)
  module Resque
    def push_with_poirot(queue, item)
      activity_id = PoirotRails::Activity.current.id
      link_id = Guid.new.to_s
      item[:args].unshift activity_id, link_id
      PoirotRails::Activity.current.logentry(:info, "Enqueue '#{item[:class]}'", ["resque"], link_id: link_id)
      push_without_poirot(queue, item)
    end
    alias_method_chain :push, :poirot
  end

  module PoirotJobWrapper
    def self.included(c)
      class << c
        def perform_with_poirot(activity_id, link_id, *args)
          PoirotRails::Activity.resume(activity_id) do
            PoirotRails::Activity.start(self.to_s, link_id: link_id, async: true) do
              begin
                perform_without_poirot(*args)
              rescue Exception => ex
                PoirotRails::Activity.current.logentry(:error, "Unhandled exception: #{ex}")
                raise
              end
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
