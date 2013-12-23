require 'time'
require 'poirot_rails/poirot_logger'
require 'poirot_rails/tee_device'
require 'poirot_rails/zmq_device'
require 'poirot_rails/client'

module PoirotRails
  mattr_accessor :client, :source

  def self.setup
    if block_given?
      yield self
    end

    log_device = TeeDevice.new("#{Rails.root}/log/poirot_#{Rails.env}.log", ZMQDevice.new)
    self.client = Client.new(log_device)

    ActiveSupport::Notifications.subscribe "start_processing.action_controller" do |*args|
      event = ActiveSupport::Notifications::Event.new *args
      self.begin_activity event
    end

    ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
      event = ActiveSupport::Notifications::Event.new *args
      self.end_activity event
    end

    old_logger = Rails.logger
    Rails.logger = PoirotLogger.new(old_logger)
    Rails.logger.level = Logger::DEBUG
  end

  def self.activity_id=(value)
    Thread.current[:activity_id] = value
  end

  def self.activity_id
    Thread.current[:activity_id]
  end

  def self.begin_activity fields
    self.activity_id = Guid.new.to_s
    self.client.begin_activity fields
  end

  def self.end_activity fields
    self.client.end_activity fields
    self.activity_id = nil
  end

  def self.logentry severity, message
    self.client.logentry severity, message
  end
end

