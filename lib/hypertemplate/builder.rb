module Hypertemplate
  module Builder
    require "hypertemplate/builder/base"
    require "hypertemplate/builder/values"
    require "hypertemplate/builder/json"
    require "hypertemplate/builder/xml"

    def self.helper_module_for(const)
      mod = Module.new
      mod.module_eval <<-EOS
        def collection(obj, *args, &block)
          #{const.name}.build(obj, *args, &block)
        end

        alias_method :member, :collection
        
        def method_missing(sym, *args, &block)
          
          # you thought meta-(meta-programming) was nasty?
          # this is nasty... help me! i am an ActionView
          # so coupled to the entire Rails stack that I need
          # this hack.
          super if @first_invocation
          @first_invocation = true
          
          #{const.name}.build_dsl(self, :root => sym.to_s, &block)
        end
        
      EOS
      mod
    end
  end
end
