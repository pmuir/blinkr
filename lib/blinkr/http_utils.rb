module Blinkr
  module HttpUtils
    
    def sanitize url, src
      begin
        uri = URI(url)
        uri = URI.join(src, url) if uri.path.nil? || uri.path.empty? || uri.relative?
        uri = URI.join(@config.base_url, uri) if uri.scheme.nil?
        uri.fragment = '' if @config.ignore_fragments
        url = uri.to_s
      rescue Exception => e
      end
      url.chomp('#').chomp('index.html')
    end

    def uid url
       url.gsub(/:|\/|\.|\?|#|%|=|&|,|~|;|\!|@|\)|\(|\s/, '_')
    end

    def retry? resp
      resp.timed_out? || (resp.code == 0 && [ "Server returned nothing (no headers, no data)", "SSL connect error", "Failure when receiving data from the peer" ].include?(resp.return_message) )
    end
 
  end
end

