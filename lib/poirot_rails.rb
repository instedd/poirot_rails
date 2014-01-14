require 'time'
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

  def self.activity_id=(value)
    Thread.current[:activity_id] = value
  end

  def self.activity_id
    Thread.current[:activity_id]
  end

  def self.metadata
    Thread.current[:activity_metadata]
  end

  def self.metadata=(metadata)
    Thread.current[:activity_metadata] = metadata
  end

  def self.add_metadata metadata
    current_md = Thread.current[:activity_metadata] || {}
    Thread.current[:activity_metadata] = current_md.merge metadata
  end

  def self.begin_activity description, meta
    self.activity_id = Guid.new.to_s
    self.metadata = meta
    self.client.begin_activity description, meta
  end

  def self.end_activity meta
    metadata = self.metadata.merge meta
    self.client.end_activity metadata
    self.activity_id = nil
    self.metadata = {}
  end

  def self.logentry severity, message
    self.client.logentry severity, message
  end
end

