begin
  require "httpclient"
rescue LoadError
end

if defined?(HTTPClient)
  class HTTPClient
    def do_request_with_poirot(method, uri, query, body, header, &block)
      if activity_id = PoirotRails::Activity.current.id
        description = "#{method.to_s.upcase} #{uri}"
        metadata = {
          host: uri.host,
          ssl: uri.scheme == "https",
          path: uri.path,
          method: method.to_s.upcase
        }

        PoirotRails::Activity.start(description, metadata) do |activity|
          header["X-Poirot-Activity-Id"] = activity.id
          response = do_request_without_poirot(method, uri, query, body, header, &block)
          code = response.code.to_s
          activity[:response_code] = code

          if code.starts_with?('4') || code.starts_with?('5')
            activity.logentry(:error, "#{code} #{response.reason}")
          else
            activity[:content_type] = response.content_type
          end

          response
        end
      else
        do_request_without_poirot(method, uri, query, body, header, &block)
      end
    end

    alias_method_chain :do_request, :poirot
  end
end
