require 'time'
require 'guid'
require 'poirot_rails/railtie'
require 'poirot_rails/middleware'
require 'poirot_rails/activity'
require 'poirot_rails/poirot_logger'
require 'poirot_rails/tee_device'
require 'poirot_rails/zmq_device'
require 'poirot_rails/client'
require 'poirot_rails/bert_service'

module PoirotRails
  mattr_accessor :client, :source, :server, :debug, :mute

  SQL_IGNORED_PAYLOADS = %w(SCHEMA EXPLAIN CACHE)

  def self.setup
    if block_given?
      yield self
    end

    log_device = ZMQDevice.new
    log_device = TeeDevice.new("#{Rails.root}/log/poirot_#{Rails.env}.log", log_device) if debug
    self.client = Client.new(log_device)

    ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
      event = ActiveSupport::Notifications::Event.new *args
      event.payload[:duration] = event.duration
      Activity.current.merge! event.payload
    end

    ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
      event = ActiveSupport::Notifications::Event.new *args
      next if SQL_IGNORED_PAYLOADS.include?(event.payload[:name])

      description = "#{event.payload[:name]} (#{event.duration.round(2)} ms) #{event.payload[:sql]}"
      metadata = {
        name: event.payload[:name],
        duration: event.duration
      }
      Activity.current.logentry(:info, description, [:sql], metadata)
    end

    old_logger = Rails.logger
    unless old_logger
      old_logger = Logger.new(STDOUT)
      old_logger.level = Logger::DEBUG
    end
    Rails.logger = PoirotLogger.new(old_logger)
    Rails.logger.level = old_logger.level
  end

  def self.logentry severity, message
    Activity.current.logentry severity, message if message.present?
  end
end

