module PoirotRails
  class Activity
    attr_reader :id, :description, :metadata
    attr_accessor :parent, :from

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

    def self.start(description, metadata = {}, &block)
      start_from(description, nil, metadata, &block)
    end

    def self.start_from(description, from, metadata = {})
      activity = Activity.new(Guid.new.to_s, description, metadata)
      activity.from = from
      Activity.push activity
      begin
        yield activity
      ensure
        Activity.pop
      end
    end

    def self.resume(activity_id)
      current_activity = Thread.current[:activity]
      begin
        Thread.current[:activity] = new(activity_id, nil)
        yield
      ensure
        Thread.current[:activity] = current_activity
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

    def logentry(severity, message, tags = nil, metadata = nil)
      PoirotRails.client.logentry(severity, message, tags, metadata) if message.present?
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
      def logentry(severity, message, tags = nil, metadata = nil)
      end
    end
  end
end
