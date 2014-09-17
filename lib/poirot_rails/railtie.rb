module PoirotRails
  class Railtie < Rails::Railtie
    config.before_initialize do |app|
      config_path = Rails.root + "config/poirot.yml"
      if config_path.exist?
        config = YAML.load_file(config_path)[Rails.env]
        if config && config["enabled"]
          # Insert the first middleware right after the logger so catched
          # exceptions are logged in the context of the activity
          app.middleware.insert_before "Rails::Rack::Logger", "PoirotRails::Middleware"

          # The second middleware is inserted after the remote IP address is
          # calculated so it takes into account modified remote IP's as
          # reported from eg. load balancers.
          app.middleware.insert_after "ActionDispatch::RemoteIp", "PoirotRails::Middleware::RemoteIp"

          PoirotRails.setup do |poirot|
            poirot.source = config["source"]
            poirot.server = config["server"]
            poirot.debug = config["debug"]
            poirot.mute = config["mute"]
          end
        end
      else
        puts "Poirot gem is installed but not configured. Please add config/poirot.yml to enable"
      end
    end
  end
end
