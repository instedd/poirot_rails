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

      body['@parent'] = Activity.current.parent.id if Activity.current.parent
      body['@from'] = Activity.current.from if Activity.current.from
      if fields[:async]
        body['@async'] = true
        fields.delete :async
      end

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

    def logentry severity, message, tags = nil, metadata = nil
      body = {
        '@message' => message[0..1024],
        '@tags' => [],
        '@pid' => "#{Process.pid}.#{Thread.current.__id__}",
        '@level' => severity,
        '@source' => PoirotRails.source,
        '@timestamp' => timestamp,
        '@activity' => Activity.current.id
      }

      body['@tags'] = tags if tags
      body['@fields'] = metadata if metadata

      event = {
        type: 'logentry',
        body: body
      }

      @device.write event.to_json + "\n"
    end

    class Null
      def begin_activity *args
      end

      def end_activity *args
      end

      def logentry *args
      end
    end
  end
end

