require "net/http"

class Net::HTTP
  def request_with_poirot(request, *args, &block)
    if activity_id = PoirotRails::Activity.current.id
      description = "#{request.method} http#{use_ssl? ? "s" : ""}://#{addr_port()}#{request.path}"
      metadata = {
        host: addr_port(),
        ssl: use_ssl?,
        path: request.path,
        method: request.method
      }

      PoirotRails::Activity.start(description, metadata) do |activity|
        request["X-Poirot-Activity-Id"] = activity.id
        response = request_without_poirot(request, *args, &block)
        activity[:response_code] = response.code

        if response.code.starts_with?('4') || response.code.starts_with?('5')
          activity.logentry(:error, "#{response.code} #{response.message}")
        else
          activity[:content_type] = response['content-type']
        end

        response
      end
    else
      request_without_poirot(request, *args, &block)
    end
  end

  alias_method_chain :request, :poirot
end
