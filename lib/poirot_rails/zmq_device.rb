module PoirotRails
  class ZMQDevice
    class << self
      def connected_devices
        @connected_devices ||= []
      end

      def reconnect
        connected_devices.each &:connect
      end
    end

    def initialize
      begin
        require 'ffi-rzmq'
      rescue LoadError
        raise "Could not require 'ffi-rzmq'. Please, add `gem 'ffi-rzmq'` to your Gemfile to use ZMQ logging with Poirot."
      end

      connect
      PoirotRails::ZMQDevice.connected_devices << self

      if defined?(::Resque)
        ::Resque.after_fork { connect }
      end

      if defined?(::Spring)
        ::Spring.after_fork { connect }
      end

      at_exit { close }
    end

    def connect
      @zmq_context = ZMQ::Context.new
      @zmq_socket = @zmq_context.socket(ZMQ::PUB)
      @zmq_socket.setsockopt ZMQ::RCVHWM, 50
      @zmq_socket.setsockopt ZMQ::SNDHWM, 50
      @zmq_socket.setsockopt ZMQ::LINGER, 1000
      @zmq_socket.connect("tcp://#{PoirotRails.server}")
    end

    def write(data)
      @zmq_socket.send_string data
    end

    def close
      PoirotRails::ZMQDevice.connected_devices.delete(self)
      @zmq_socket.close
    end
  end
end

