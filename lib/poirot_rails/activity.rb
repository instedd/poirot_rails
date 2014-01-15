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

    def self.none
      @none ||= new nil, "(no activity)"
    end
  end
end
