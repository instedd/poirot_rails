module PoirotRails
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      metadata = {
        method: request.request_method,
        path: request.path,
        query_string: request.query_string,
        user_agent: request.user_agent,
        remote_address: request.remote_ip,
        referer: request.referer
      }

      if muted?(request.path)
        Activity.mute { @app.call(env) }
      else
        Activity.start("#{request.request_method} #{request.path}", metadata) do
          @app.call(env)
        end
      end
    end

    def muted?(path)
      return false unless PoirotRails.mute
      PoirotRails.mute.any? { |mute| path.start_with?(mute) }
    end

  end
end
