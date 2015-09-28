if defined?(ActiveJob::Base)
  class ActiveJob::Base
    around_enqueue do |job, block|
      activity_id = PoirotRails::Activity.current.id
      link_id = Guid.new.to_s
      job.arguments.push({"activity_id" => activity_id, "link_id" => link_id})
      PoirotRails::Activity.current.logentry(:info, "Enqueue '#{job.class}'", ["active_job"], link_id: link_id)
      block.call
    end

    around_perform do |job, block|
      return block.call unless has_poirot_argument(job.arguments)
      poirot_arg = job.arguments.pop
      activity_id, link_id = poirot_arg["activity_id"], poirot_arg["link_id"]
      PoirotRails::Activity.resume(activity_id) do
        PoirotRails::Activity.start(job.class.name, link_id: link_id, async: true) do
          begin
            block.call
          rescue Exception => ex
            PoirotRails::Activity.current.logentry(:error, "Unhandled exception: #{ex}")
            raise
          end
        end
      end
    end

    private

    def has_poirot_argument(args)
      last_arg = args.last
      last_arg.is_a?(Hash) && last_arg.has_key?("activity_id") && last_arg.has_key?("link_id")
    end
  end
end
