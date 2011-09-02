module Hypertemplate
  module Builder
    class Base

      # field id is quite common
      undef_method :id if respond_to?(:id)

      class << self
        
        def media_types
          @media_types
        end

        def extend_media_types(media_types)
          @media_types.push(*media_types)
        end

        def build_dsl(obj, options = {}, &block)
          recipe = block_given? ? block : options.delete(:recipe)
          raise Hypertemplate::BuilderError.new("Recipe required to build representation.") unless recipe.respond_to?(:call)

          builder = self.new(nil, options)
          copy_internal_variables(builder, obj)
          builder.instance_variable_set :@view, obj
          def builder.method_missing(name, *args, &block)
            begin
              @view.send name, *args, &block
            rescue
              super
            end
          end
          builder.instance_exec(obj, &recipe)

          builder.representation
        end
        
        def copy_internal_variables(builder, obj)
          # TODO this is nasty. i am sorry.
          obj.instance_variables.each do |name|
            builder.instance_variable_set name, obj.instance_variable_get(name)
          end
        end

        def build(obj, options = {}, &block)
          recipe = block_given? ? block : options.delete(:recipe)
          raise Hypertemplate::BuilderError.new("Recipe required to build representation.") unless recipe.respond_to?(:call)

          builder = self.new(obj, options)

          if recipe.arity==-1
            builder.instance_exec(&recipe)
          else
            recipe.call(*[builder, obj, options][0, recipe.arity])
          end

          builder.representation
        end

        def helper
          @helper_module ||= Hypertemplate::Builder.helper_module_for(self)
        end

        def collection_helper_default_options(options = {}, &block)
          generic_helper(:collection, options, &block)
        end

        def member_helper_default_options(type, options = {}, &block)
          generic_helper(:member, options, &block)
        end

        def generic_helper(section, options = {}, &block)
          helper.send(:remove_method, section)
          var_name = "@@more_options_#{section.to_s}".to_sym
          helper.send(:class_variable_set, var_name, options)
          helper.module_eval <<-EOS
            def #{section.to_s}(obj, *args, &block)
              #{var_name}.merge!(args.shift)
              args.unshift(#{var_name})
              #{self.name}.build(obj, *args, &block)
            end
          EOS
        end
      end

      # adds a key and value pair to the representation
      # example:
      #
      # name 'guilherme'
      def method_missing(sym, *args, &block)
        values do |v|
          v.send sym, *args, &block
        end
      end
      
      def ns(*args, &block)
        values do |v|
          v.send(:[], *args, &block)
        end
      end

      # writes a key and value pair to the representation
      # example:
      #
      # write :name, "guilherme"
      def write(sym, val)
        values do |v|
          v.send sym, val
        end
      end

      
      def each(collection, options = {}, &block)
        options[:collection] = collection
        members(options, &block)
      end

    end
  end
end
