require "net/http"

class Net::HTTP
  def request_with_poirot(request, *args, &block)
    activity_id = PoirotRails::Activity.current.id
    if activity_id
      link_id = Guid.new.to_s
      request["X-Poirot-Activity-Id"] = activity_id
      request["X-Poirot-Link-Id"] = link_id
      PoirotRails::Activity.current.logentry(:info, "#{request.method} http#{use_ssl? ? "s" : ""}://#{addr_port()}#{request.path}", ["net", "http"], link_id: link_id)
    end
    request_without_poirot(request, *args, &block)
  end

  alias_method_chain :request, :poirot
end
