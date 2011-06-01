require 'hypertemplate' unless defined? ::Hypertemplate

module Hypertemplate
  module RegistryContainer
    
    def hypertemplate_registry
      @hypertemplate || use_hypertemplate
    end
    
    def use_hypertemplate(&block)
      @hypertemplate = ::Hypertemplate::Registry.new
      if block_given?
        yield @hypertemplate
      else
        @hypertemplate << ::Hypertemplate::Builder::Json
        @hypertemplate << ::Hypertemplate::Builder::Xml
      end
      @hypertemplate
    end
    
  end
end

module ActionController
  class Base
    include Hypertemplate::RegistryContainer
  end
end

module Hypertemplate
  module Hook
    module Rails

      class Hypertemplate < ::ActionView::TemplateHandler
        include ::ActionView::TemplateHandlers::Compilable

        def compile(template)
          "@content_type_helpers = controller.hypertemplate_registry[self.response.content_type].helper; " +
          "extend @content_type_helpers; " +
          "extend Hypertemplate::Hook::Rails::Helpers; " +
          "code_block = lambda { #{template.source} };" +
          "builder = code_block.call; " +
          "builder"
        end
      end

      module Rails3Adapter
        def _pick_partial_template(path) #:nodoc:
          return path unless path.is_a?(String)
          prefix = controller_path unless path.include?(?/)
          find_template(path, prefix, true).instance_eval do
            unless respond_to?(:path)
              def path; virtual_path end
            end
            self
          end
        end
      end
      
      module Helpers

        def self.extend_object(base)
          super
          base.extend(Rails3Adapter) unless base.respond_to?(:_pick_partial_template)
        end
        
        # Load a partial template to execute in describe
        #
        # For example:
        #
        # Passing the current context to partial in template:
        #
        #  member(@album) do |member, album|
        #    partial('member', binding)
        #  end
        #
        # in partial:
        #
        #  member.links << link(:rel => :artists, :href => album_artists_url(album))
        #
        # Or passing local variables assing
        #
        # collection(@albums) do |collection|
        #   collection.members do |member, album|
        #     partial("member", :locals => {:member => member, :album => album})
        #   end
        # end
        #
        def partial(partial_path, caller_binding = nil)
          template = _pick_partial_template(partial_path)

          # Create a context to assing variables
          if caller_binding.kind_of?(Hash)
            Proc.new do
              extend @content_type_helpers
              context = eval("(class << self; self; end)", binding)

              caller_binding.fetch(:locals, {}).each do |k, v|
                context.send(:define_method, k.to_sym) { v }
              end

              partial(partial_path, binding)
            end.call
          else
            eval(template.source, caller_binding, template.path)
          end
        end
      end

    private
      
      def self.registry
        if defined? ::ActionView::Template and ::ActionView::Template.respond_to?(:register_template_handler)
          ::ActionView::Template
        else
          if defined? ::ActionController::Base
            ::ActionController::Base.exempt_from_layout :hyper
            ::ActionController::Base.exempt_from_layout :hypertemplate
            ::ActionController::Base.exempt_from_layout :tokamak
          end
          ::ActionView::Base
        end
      end

      registry.register_template_handler(:hyper, Hypertemplate)
      registry.register_template_handler(:hypertemplate, Hypertemplate)
      registry.register_template_handler(:tokamak, Hypertemplate)

    end
  end
end
