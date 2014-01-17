require 'time'
require 'poirot_rails/activity'
require 'poirot_rails/poirot_logger'
require 'poirot_rails/tee_device'
require 'poirot_rails/zmq_device'
require 'poirot_rails/client'
require 'poirot_rails/bert_service'

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
      payload = event.payload
      description = "#{payload[:method]} #{payload[:path]}"
      meta = event.as_json.with_indifferent_access
      self.begin_activity description, meta
    end

    ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
      event = ActiveSupport::Notifications::Event.new *args
      meta = event.as_json.with_indifferent_access
      self.end_activity meta
    end

    old_logger = Rails.logger
    unless old_logger
      old_logger = Logger.new(STDOUT)
      old_logger.level = Logger::DEBUG
    end
    Rails.logger = PoirotLogger.new(old_logger)
    Rails.logger.level = old_logger.level
  end

  def self.current
    Thread.current[:activity] || Activity.none
  end

  def self.add_metadata metadata
    self.current.merge! metadata if self.current
  end

  def self.begin_activity description, meta
    self.current = Activity.new Guid.new.to_s, description, meta
    self.client.begin_activity description, meta
  end

  def self.end_activity meta
    self.current.merge! meta
    self.client.end_activity self.current.metadata
    self.current = Activity.none
  end

  def self.logentry severity, message
    self.client.logentry severity, message
  end

  private

  def self.current=(activity)
    Thread.current[:activity] = activity
  end
end

