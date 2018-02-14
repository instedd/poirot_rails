if defined?(Delayed::Job)
  module Delayed
    module Backend
      module Base
        module ClassMethods
          alias_method :enqueue_without_poirot, :enqueue

          def enqueue(*args)
            if activity_id = PoirotRails::Activity.current.id
              link_id = Guid.new.to_s
              args[0].instance_variable_set :@_poirot_activity_id, activity_id
              args[0].instance_variable_set :@_poirot_link_id, link_id
              PoirotRails::Activity.current.logentry(:info, "Enqueue '#{args[0].class}'", ["delayed_job"], link_id: link_id)
            end
            enqueue_without_poirot(*args)
          end
        end

        alias_method :invoke_job_without_poirot, :invoke_job

        def invoke_job
          if activity_id = payload_object.instance_variable_get(:@_poirot_activity_id)
            PoirotRails::Activity.resume(activity_id) do
              link_id = payload_object.instance_variable_get(:@_poirot_link_id)
              invoke_job_in_new_activity(link_id)
            end
          else
            invoke_job_in_new_activity
          end
        end

        def invoke_job_in_new_activity(link_id = nil)
          metadata = { async: true, attempt: attempts + 1 }
          metadata[:link_id] = link_id if link_id

          (payload_object.instance_variables - [:@_poirot_activity_id, :@_poirot_link_id]).each do |ivar|
            metadata[ivar.to_s[1..-1]] = payload_object.instance_variable_get(ivar)
          end

          if respond_to?(:id)
            description = "#{payload_object.class} (#{id})"
            metadata[:delayed_job_id] = id
          else
            description = payload_object.class.to_s
          end

          PoirotRails::Activity.start(description, metadata) do
            begin
              invoke_job_without_poirot
            rescue Exception => ex
              PoirotRails::Activity.current.logentry(:error, "Unhandled exception: #{ex}")
              raise
            end
          end
        end
      end
    end
  end
end
