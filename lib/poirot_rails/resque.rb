begin
  require "resque"
rescue LoadError
end

if defined?(Resque)
  module Resque
    alias_method :push_without_poirot, :push

    def push(queue, item)
      activity_id = PoirotRails::Activity.current.id
      link_id = Guid.new.to_s
      item[:args].unshift activity_id, link_id
      PoirotRails::Activity.current.logentry(:info, "Enqueue '#{item[:class]}'", ["resque"], link_id: link_id)
      push_without_poirot(queue, item)
    end
  end

  module PoirotJobWrapper
    alias_method :perform_without_poirot, :perform

    def self.included(c)
      class << c
        alias_method :perform_without_poirot, :perform

        def perform(activity_id, link_id, *args)
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
      end
    end
  end

  class Resque::Job
    alias_method :perform_without_poirot, :perform

    def perform
      unless payload_class.include?(PoirotJobWrapper)
        payload_class.include(PoirotJobWrapper)
      end
      perform_without_poirot
    end
  end

end
