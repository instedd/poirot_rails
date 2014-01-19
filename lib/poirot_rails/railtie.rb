module PoirotRails
  class Railtie < Rails::Railtie
    config.before_initialize do |app|
      app.middleware.insert_before "Rails::Rack::Logger", "PoirotRails::Middleware"
      PoirotRails.setup
    end
  end
end
