require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class Hypertemplate::Builder::ValuesTest < Test::Unit::TestCase

  def test_should_not_remove_important_methods
    values = Hypertemplate::Builder::Values.new(nil)
    assert values.respond_to? :method_missing
    assert values.respond_to? :object_id
    assert values.respond_to? :respond_to?
  end
  
end
