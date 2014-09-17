module PoirotRails
  module DelayedJob
    def before(job)
      desc = description rescue "DelayedJob ##{job.id}"
      activity = Activity.new(Guid.new.to_s, desc, { delayed_job_id: job.id })
      Activity.push activity
    end

    def after(job)
      Activity.pop
    end

    def error(job, exception)
      PoirotRails.logentry :error, "#{exception.class.name}: #{exception.message}"
    end
  end
end

