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
        id: PoirotRails.current.id,
        body: body
      }

      @device.write event.to_json + "\n"
    end

    def end_activity fields
      now = timestamp

      body = {
        '@fields' => fields,
        '@tags' => [],
        '@end' => now,
        '@timestamp' => now
      }

      event = {
        type: 'end_activity',
        id: PoirotRails.current.id,
        body: body
      }

      @device.write event.to_json + "\n"
    end

    def logentry severity, message
      body = {
        '@message' => message,
        '@tags' => [],
        '@pid' => "#{Process.pid}.#{Thread.current.__id__}",
        '@level' => severity,
        '@source' => PoirotRails.source,
        '@timestamp' => timestamp,
        '@activity' => PoirotRails.current.id
      }

      event = {
        type: 'logentry',
        body: body
      }

      @device.write event.to_json + "\n"
    end
  end
end

