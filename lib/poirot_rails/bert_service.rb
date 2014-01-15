module PoirotRails
  class BertService
    extend Forwardable

    attr_reader :service

    def initialize(host, port, timeout = nil)
      @service = BERTRPC::Service.new(host, port, timeout)
    end

    def_delegators :@service, :host, :host=, :port, :port=, :timeout, :timeout=

    def cast(options = nil)
      Request.new(self, :cast, options)
    end

    def call(options = nil)
      Request.new(self, :call, options)
    end

    def wrap(kind, options, mod, func, args)
      activity_id = PoirotRails.current.id
      if kind == :call
        @service.send(kind, options).poirot_bert.execute_call(activity_id, mod, func, args)
      else
        @service.send(kind, options).poirot_bert.execute_cast(activity_id, mod, func, args)
      end
    end
  end

  class Request
    attr_accessor :service, :kind, :options

    def initialize(service, kind, options)
      @service = service
      @kind = kind
      @options = options
    end

    def method_missing(name, *args)
      Mod.new(@service, self, name)
    end
  end

  class Mod
    attr_accessor :service, :request, :module
    def initialize(service, request, name)
      @service = service
      @request = request
      @module = name
    end

    def method_missing(name, *args)
      @service.wrap(@request.kind, @request.options, @module, name, args)
    end
  end
end

