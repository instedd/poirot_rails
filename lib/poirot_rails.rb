require 'time'
require 'poirot_rails/json_logger'
require 'poirot_rails/tee_device'
require 'poirot_rails/zmq_device'

module PoirotRails
  def self.setup
    ActiveSupport::Notifications.subscribe "start_processing.action_controller" do |*args|
      event = ActiveSupport::Notifications::Event.new *args

      self.activity_id = Guid.new.to_s
      Rails.logger.info do 
        { '_type' => 'begin_activity', '@fields' => event }
      end
    end

    ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
      event = ActiveSupport::Notifications::Event.new *args

      Rails.logger.info do 
        { '_type' => 'end_activity', '@fields' => event }
      end
      activity_id = nil
    end

    log_device = TeeDevice.new("#{Rails.root}/log/poirot_#{Rails.env}.log", ZMQDevice.new)
    Rails.logger = JsonLogger.new(log_device)
    Rails.logger.level = Logger::DEBUG
    Rails.logger.progname = 'cepheid-web'
  end

  def self.activity_id=(value)
    Thread.current[:activity_id] = value
  end

  def self.activity_id
    Thread.current[:activity_id]
  end
end

