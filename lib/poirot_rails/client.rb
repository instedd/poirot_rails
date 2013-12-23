module PoirotRails
  class Client
    def initialize(device)
      @device = device
    end

    def begin_activity fields
      body = {
        '_type' => 'activity',
        '@fields' => fields,
        '@tags' => [],
        '@pid' => "#{Process.pid}.#{Thread.current.__id__}",
        '@source' => PoirotRails.source,
        '@timestamp' => Time.now.utc.iso8601
      }
      
      event = {
        type: 'begin_activity',
        id: PoirotRails.activity_id,
        body: body
      }

      @device.write event.to_json + "\n"
    end

    def end_activity fields
      body = {
        '_type' => 'activity',
        '@fields' => fields,
        '@tags' => [],
        '@pid' => "#{Process.pid}.#{Thread.current.__id__}",
        '@source' => PoirotRails.source,
        '@timestamp' => Time.now.utc.iso8601
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
        '@timestamp' => Time.now.utc.iso8601,
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

