module PoirotRails
  class Client
    def initialize(device)
      @device = device
    end

    def timestamp
      Time.now.utc.iso8601(6)
    end

    def begin_activity description, fields
      return unless Activity.current.id
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
        id: Activity.current.id,
        body: body
      }

      @device.write event.to_json + "\n"
    end

    def end_activity fields
      return unless Activity.current.id
      now = timestamp

      body = {
        '@fields' => fields,
        '@tags' => [],
        '@end' => now,
        '@timestamp' => now
      }

      event = {
        type: 'end_activity',
        id: Activity.current.id,
        body: body
      }

      @device.write event.to_json + "\n"
    end

    def logentry severity, message
      body = {
        '@message' => message[0..1024],
        '@tags' => [],
        '@pid' => "#{Process.pid}.#{Thread.current.__id__}",
        '@level' => severity,
        '@source' => PoirotRails.source,
        '@timestamp' => timestamp,
        '@activity' => Activity.current.id
      }

      event = {
        type: 'logentry',
        body: body
      }

      @device.write event.to_json + "\n"
    end
  end
end

