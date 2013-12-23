module PoirotRails
  class TeeDevice
    def initialize(*devices)
      @devices = devices.map do |device|
        if device.respond_to?(:write) && device.respond_to?(:close)
          device
        else
          Logger::LogDevice.new device
        end
      end
    end

    def write(data)
      @devices.each do |device|
        device.write(data)
      end
    end

    def close
      @devices.each do |device|
        device.close
      end
    end
  end
end

