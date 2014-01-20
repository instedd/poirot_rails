require 'time'
require 'poirot_rails/railtie'
require 'poirot_rails/middleware'
require 'poirot_rails/activity'
require 'poirot_rails/poirot_logger'
require 'poirot_rails/tee_device'
require 'poirot_rails/zmq_device'
require 'poirot_rails/client'
require 'poirot_rails/bert_service'

module PoirotRails
  mattr_accessor :client, :source, :server

  def self.setup
    if block_given?
      yield self
    end

    log_device = TeeDevice.new("#{Rails.root}/log/poirot_#{Rails.env}.log", ZMQDevice.new)
    self.client = Client.new(log_device)

    ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
      event = ActiveSupport::Notifications::Event.new *args
      event.payload[:duration] = event.duration
      Activity.current.merge! event.payload
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
    self.client.logentry severity, message if message.present?
  end
end

