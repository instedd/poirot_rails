module PoirotRails
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      path = env['REQUEST_PATH'] || env['ORIGINAL_FULLPATH']
      metadata = {
        method: env['REQUEST_METHOD'],
        path: path,
        user_agent: env['HTTP_USER_AGENT']
      }

      from_activity = env['HTTP_X_POIROT_ACTIVITY_ID']
      if link_id = env['HTTP_X_POIROT_LINK_ID']
        metadata[:link_id] = link_id
      end

      if muted?(path)
        Activity.mute { @app.call(env) }
      else
        Activity.start_from("#{env['REQUEST_METHOD']} #{path}", from_activity, metadata) do
          @app.call(env)
        end
      end
    end

    def muted?(path)
      return false unless PoirotRails.mute
      PoirotRails.mute.any? { |mute| path.start_with?(mute) }
    end

    class RemoteIp
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)
        Activity.current.merge! remote_address: request.remote_ip,
          query_string: request.query_string,
          referer: request.referer
        @app.call(env)
      end
    end

  end
end
