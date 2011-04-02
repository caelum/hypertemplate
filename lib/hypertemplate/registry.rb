module Hypertemplate
  class Registry

    def initialize
      @media_types = {}
    end

    def <<(handler)
      handler.media_types.each do |type|
        @media_types[type] = handler
      end
    end

    def [](media_type)
      @media_types[media_type[/^([^\s\;]+)/, 1]]
    end
    
    def []=(media_type, handler)
      @media_types[media_type] = handler
    end

  end
end

