module PoirotRails
  class Client
    def initialize(device)
      @device = device
    end

    def timestamp
      Time.now.utc.iso8601(6)
    end

    def begin_activity description, fields
      now = timestamp

      body = {
        '_type' => 'activity',
        '@description' => description,
        '@fields' => fields,
        '@tags' => [],
        '@pid' => "#{Process.pid}.#{Thread.current.__id__}",
        '@source' => PoirotRails.source,
        '@start' => now,
        '@timestamp' => now
      }
      
      event = {
        type: 'begin_activity',
        id: PoirotRails.activity_id,
        body: body
      }

      @device.write event.to_json + "\n"
    end

    def end_activity fields
      now = timestamp

      body = {
        '_type' => 'activity',
        '@fields' => fields,
        '@tags' => [],
        '@pid' => "#{Process.pid}.#{Thread.current.__id__}",
        '@source' => PoirotRails.source,
        '@end' => now,
        '@timestamp' => now
      }
      
      event = {
        type: 'end_activity',
        id: PoirotRails.activity_id,
        body: body
      }

      @device.write event.to_json + "\n"
    end

    def logentry severity, message
      body = {
        '_type' => 'logentry',
        '@message' => message,
        '@tags' => [],
        '@pid' => "#{Process.pid}.#{Thread.current.__id__}",
        '@level' => severity,
        '@source' => PoirotRails.source,
        '@timestamp' => timestamp,
        '@activity' => PoirotRails.activity_id
      }
      
      event = {
        type: 'logentry',
        body: body
      }

      @device.write event.to_json + "\n"
    end
  end
end

