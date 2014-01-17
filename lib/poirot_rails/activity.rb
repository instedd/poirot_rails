module PoirotRails
  class Activity
    attr_reader :id, :description, :metadata

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

    class None
      def id
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
