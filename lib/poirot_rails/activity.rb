module PoirotRails
  class Activity
    attr_reader :id, :description, :metadata
    attr_accessor :parent

    def initialize(id, description, metadata = {})
      @id = id
      @description = description
      @metadata = metadata
    end

    def []=(key, value)
      @metadata[key] = value
    end

    def merge!(more)
      @metadata.merge! more
    end

    def self.start(description, metadata = {})
      activity = Activity.new(Guid.new.to_s, description, metadata)
      Activity.push activity
      begin
        yield
      ensure
        Activity.pop
      end
    end

    def self.push(activity)
      activity.parent = Thread.current[:activity]
      Thread.current[:activity] = activity
      PoirotRails.client.begin_activity activity.description, activity.metadata
    end

    def self.pop
      PoirotRails.client.end_activity current.metadata
      Thread.current[:activity] = current.parent
    end

    def self.current
      Thread.current[:activity] || Activity.none
    end

    class None
      def id
        nil
      end

      def parent
        nil
      end

      def description
        "(no activity)"
      end

      def metadata
        {}
      end

      def []=(key, value)
      end

      def merge!(more)
      end
    end

    def self.none
      @none ||= None.new
    end
  end
end
