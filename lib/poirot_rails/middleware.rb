module PoirotRails
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      metadata = {
        method: env['REQUEST_METHOD'],
        path: env['REQUEST_PATH'],
        remote_address: env['REMOTE_ADDR'],
        user_agent: env['HTTP_USER_AGENT']
      }
      Activity.start("#{env['REQUEST_METHOD']} #{env['REQUEST_PATH']}", metadata) do
        @app.call(env)
      end
    end
  end
end
