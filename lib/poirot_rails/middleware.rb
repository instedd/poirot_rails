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
        remote_address: env['REMOTE_ADDR'],
        user_agent: env['HTTP_USER_AGENT']
      }

      if muted?(path)
        Activity.mute { @app.call(env) }
      else
        Activity.start("#{env['REQUEST_METHOD']} #{path}", metadata) do
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
