module Hypertemplate
  module Builder
    class Cache #< BasicObject
      attr_accessor :builder

      def initialize(key, builder, &block)
        @key = key
        @builder = builder

        if cached?
          raw = cache.read(cache_key)

          if builder.class == Xml
            data = Nokogiri::XML(raw)
          else
            data = MultiJson.decode(raw)
          end
        else
          _builder = builder.class.new({})
          yield _builder
          data = _builder.raw

          cache.write(cache_key, _builder.representation)
        end

        if current = builder.instance_variable_get('@current') # JSON
          current.merge!(data)
        else # XML
          parent = builder.instance_variable_get('@parent')
          data.root.children.each do |element|
            element.parent = parent
          end
        end
      end

      def cached?
        cache.exist?(cache_key)
      end

      def cache
        Hypertemplate::Builder::Base.cache
      end

      def cache_key
        @_generated_key ||= "#{@key}_#{builder.class.to_s.split('::').last}"
      end
    end
  end
end