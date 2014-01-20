require 'zmq'

module PoirotRails
  class ZMQDevice
    def initialize
      @zmq_context = ZMQ::Context.new
      @zmq_socket = @zmq_context.socket(ZMQ::PUB)
      @zmq_socket.setsockopt ZMQ::HWM, 50
      @zmq_socket.setsockopt ZMQ::LINGER, 1000
      @zmq_socket.connect("tcp://#{PoirotRails.server}")

      at_exit { close }
    end

    def write(data)
      @zmq_socket.send data
    end

    def close
      @zmq_socket.close
    end
  end
end

