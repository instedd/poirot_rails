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

    def self.mute
      Activity.push MUTE
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
      Thread.current[:activity] || NONE
    end

    def logentry(severity, message)
      PoirotRails.client.logentry severity, message if message.present?
    end

    class Null < self
      def initialize(name)
        super(nil, name)
      end

      def metadata
        {}
      end

      def []=(key, value)
      end

      def merge!(more)
      end
    end

    class << NONE = Null.new("(no activity)")
    end

    class << MUTE = Null.new("(mute activity)")
      def logentry(severity, message)
      end
    end
  end
end
