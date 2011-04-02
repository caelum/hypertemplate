require 'hypertemplate' unless defined? ::Hypertemplate
require "hypertemplate/hook/tilt"

module Rack
  class Hypertemplate
    
    def initialize(app)
      @app = app
      @registry = ::Hypertemplate::Registry.new
      if block_given?
        yield @registry
      else
        @registry << ::Hypertemplate::Builder::Json
        @registry << ::Hypertemplate::Builder::Xml
      end
    end
    
    def call(env)
      env["hypertemplate"] = @registry
      @app.call(env)
    end
    
  end
end

module Hypertemplate
  module Hook
    module Sinatra

      module ::Sinatra::Templates

        def tokamak(template, options={}, locals={})
          hyler(template, options, locals)
        end
        
        def hyper(template, options={}, locals={})
          options.merge! :layout => false, :media_type => response["Content-Type"]
          render :hyper, template, options, locals
        end

      end
    end
  end
end
