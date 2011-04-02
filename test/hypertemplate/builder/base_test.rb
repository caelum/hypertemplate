require 'test_helper'

class Hypertemplate::Builder::BaseTest < Test::Unit::TestCase

  class SomeBuilder < Hypertemplate::Builder::Base
    def self.media_types
      ["valid/media_type"]
    end
  end

  class AnotherBuilder < Hypertemplate::Builder::Base
    def self.media_types
      ["valid/media_type", "another_valid/media_type"]
    end
  end

  class YetAnotherBuilder < Hypertemplate::Builder::Base
    def self.media_types
      ["yet_another_valid/media_type"]
    end
  end

  def setup
    @registry = Hypertemplate::Registry.new
    @registry << SomeBuilder
    @registry << AnotherBuilder
    @registry << YetAnotherBuilder
  end

  def test_should_support_media_type_registering
    @registry["runtime/media_type"] = AnotherBuilder
    assert_equal AnotherBuilder   , @registry["runtime/media_type"]
  end
  
  def test_should_lookup_valid_media_types
    assert_equal AnotherBuilder   , @registry["valid/media_type"]
    assert_equal AnotherBuilder   , @registry["another_valid/media_type"]
    assert_equal YetAnotherBuilder, @registry["yet_another_valid/media_type"]
  end
  
  def test_should_lookup_invalid_media_types
    assert_equal nil   , @registry["invalid/media_type"]
  end
    
end
