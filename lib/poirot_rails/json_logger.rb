module PoirotRails
  class JsonLogger < Logger
    def <<(msg)
      add(UNKNOWN, msg)
    end

    def add(severity, message = nil, progname = nil, &block)
      severity ||= UNKNOWN
      if @logdev.nil? or severity < @level
        return true
      end
      progname ||= @progname
      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
          progname = @progname
        end
      end
      if message.is_a?(Hash)
        body = message
      else
        body = { 
          '_type' => 'logentry',
          '@message' => message,
        }
      end
      body.merge!(
        '@tags' => [],
        '@pid' => "#{Process.pid}.#{Thread.current.__id__}",
        '@level' => format_severity(severity).downcase,
        '@source' => @progname,
        '@timestamp' => Time.now.utc.iso8601,
      )
      if ['begin_activity', 'end_activity'].include?(body['_type'])
        type = body['_type']
        id = body['_id'] = PoirotRails.activity_id
        body['@parent'] = nil
        body['_type'] = 'activity'
      else
        type = 'logentry'
        id = nil
        body['@activity'] = PoirotRails.activity_id
      end

      event = { type: type, id: id, body: body }

      @logdev.write event.to_json + "\n"
      true
    end
  end
end

