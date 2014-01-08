module PoirotRails
  class PoirotLogger < Logger
    def initialize(delegate)
      @delegate = delegate
    end

    def <<(msg)
      add(UNKNOWN, msg)
    end

    def add(severity, message = nil, progname = nil, &block) 
      severity ||= UNKNOWN
      if severity < @level
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

      clean_message = message.gsub(%r{\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]},'')
      PoirotRails.logentry format_severity(severity).downcase, clean_message
      @delegate.add(severity, message, progname)
    end
  end
end

