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
require 'poirot_rails/delayed_job'
require 'poirot_rails/resque'
require 'poirot_rails/active_job'
require 'poirot_rails/net_http'
require 'poirot_rails/httpclient'

module PoirotRails
  mattr_accessor :client, :source, :server, :debug, :mute, :stdout, :suppress_rails_log

  SQL_IGNORED_PAYLOADS = %w(SCHEMA EXPLAIN CACHE)

  def self.setup
    if block_given?
      yield self
    end

    devices = []
    devices << "#{Rails.root}/log/poirot_#{Rails.env}.log" if debug
    devices << ZMQDevice.new if server
    devices << STDOUT if stdout
    self.client = Client.new(TeeDevice.new(*devices))

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
    Rails.logger = PoirotLogger.new(suppress_rails_log ? nil : old_logger)
    Rails.logger.level = old_logger.try(:level) || Logger::DEBUG
  end

  def self.logentry severity, message
    Activity.current.logentry severity, message if message.present?
  end

  self.client = Client::Null.new
end

