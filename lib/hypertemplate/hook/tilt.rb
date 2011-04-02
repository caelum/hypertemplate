require 'hypertemplate' unless defined? ::Hypertemplate

module Hypertemplate
  module Hook
    module Tilt
      
      class HypertemplateTilt
        
        def initialize
          @registry = Hypertemplate::Registry.new
        end
        
        # unfortunately Tilt uses a global registry
        def new(view = nil, line = 1, options = {}, &block)
          HypertemplateTemplate.new(@registry, view, line,options, &block)
        end
        
      end

      class HypertemplateTemplate < ::Tilt::Template
        
        def initialize(registry, view = nil, line = 1,options = {}, &block)
          super(view, line, options, &block)
          @registry = registry
        end
        
        def initialize_engine
          return if defined?(::Hypertemplate)
          require_template_library 'hypertemplate'
        end

        def prepare
          @media_type = options[:media_type]
          raise Hypertemplate::BuilderError.new("Content type required to build representation.") unless @media_type
        end

        def precompiled_preamble(locals)
          local_assigns = super
          <<-RUBY
            begin
              unless self.class.method_defined?(:hypertemplate_registry)
                def hypertemplate_registry
                  env['hypertemplate']
                end
              end
              extend hypertemplate_registry[#{@media_type.inspect}].helper
              #{local_assigns}
          RUBY
        end

        def precompiled_postamble(locals)
          <<-RUBY
            end
          RUBY
        end

        def precompiled_template(locals)
          data.to_str
        end
      end

      ::Tilt.register 'hypertemplate', HypertemplateTilt.new
      ::Tilt.register 'tokamak', HypertemplateTilt.new
      ::Tilt.register 'hyper', HypertemplateTilt.new

    end
  end
end
