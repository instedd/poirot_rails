module PoirotRails
  class Railtie < Rails::Railtie
    config.before_initialize do |app|
      config_path = Rails.root + "config/poirot.yml"
      if config_path.exist?
        config = YAML.load_file(config_path)[Rails.env]
        if config && config["enabled"]
          app.middleware.insert_before "Rails::Rack::Logger", "PoirotRails::Middleware"
          PoirotRails.setup do |poirot|
            poirot.source = config["source"]
            poirot.server = config["server"]
          end
        end
      else
        puts "Poirot gem is installed but not configured. Please add config/poirot.yml to enable"
      end
    end
  end
end
