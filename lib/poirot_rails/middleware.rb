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
      Activity.start("#{env['REQUEST_METHOD']} #{path}", metadata) do
        @app.call(env)
      end
    end
  end
end
