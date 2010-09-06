module Rack
  class SslEnforcer
    
    def initialize(app, options = {})
      @app, @options = app, options
    end
    
    def call(env)
      @req = Rack::Request.new(env)
      if enforce_ssl?(env)
        scheme = 'https' unless ssl_request?(env)
      elsif ssl_request?(env) && @options[:strict]
        scheme = 'http'
      end
      
      if scheme
        location = @options[:redirect_to] || "#{scheme}://#{@req.host}#{@req.path}"
        body     = "<html><body>You are being <a href=\"#{location}\">redirected</a>.</body></html>"
        [301, { 'Content-Type' => 'text/html', 'Location' => location }, [body]]
      else
        @app.call(env)
      end
    end
    
  private
    
    def ssl_request?(env)
      (env['HTTP_X_FORWARDED_PROTO'] || @req.scheme) == 'https'
    end
    
    def enforce_ssl?(env)
      if @options[:only]
        rules = [@options[:only]].flatten
        rules.any? do |pattern|
          if pattern.is_a?(Regexp)
            @req.path =~ pattern
          else
            @req.path[0,pattern.length] == pattern
          end
        end
      else
        true
      end
    end
    
  end
end