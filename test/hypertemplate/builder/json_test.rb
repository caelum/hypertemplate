require 'test_helper'

class Hypertemplate::Builder::JsonTest < Test::Unit::TestCase

  def setup
    @registry = Hypertemplate::Registry.new
    @registry << DummyAtom
  end

  def test_media_type_should_be_json
    assert_equal ["application/json"], Hypertemplate::Builder::Json.media_types
  end
  
  def test_custom_values_and_iterating_over_members
    obj = [{ :foo => "bar" }]
    json = Hypertemplate::Builder::Json.build(obj) do |collection|
      collection.values do |values|
        values.id "an_id"
      end
      
      collection.members do |member, some_foos|
        member.values do |values|
          values.id some_foos[:foo]
        end        
      end
    end
    
    hash = JSON.parse(json).extend(Methodize)
    
    assert_equal "an_id", hash.id
    assert_equal "bar"  , hash.members.first.id
    assert hash.members.kind_of?(Array)
  end

  def test_empty_value_as_nil
    obj = {}
    json = Hypertemplate::Builder::Json.build(obj) do |collection|
      collection.values do |values|
        values.empty_value 
      end
    end
    
    hash = JSON.parse(json).extend(Methodize)
    
    assert_equal nil    , hash.empty_value
  end

  def test_root_set_on_builder
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    json = Hypertemplate::Builder::Json.build(obj, :root => "foos") do |collection|
      collection.values do |values|
        values.id "an_id"
      end
      
      collection.members do |member, some_foos|
        member.values do |values|
          values.id some_foos[:foo]
        end        
      end
    end
    
    hash = JSON.parse(json).extend(Methodize)
    
    assert hash.has_key?("foos")
    assert_equal "an_id", hash.foos.id
    assert_equal "bar"  , hash.foos.members.first.id
  end
  
  def test_collection_set_on_members
    obj = { :foo => "bar" }
    a_collection = [1,2,3,4]
    json = Hypertemplate::Builder::Json.build(obj) do |collection|
      collection.values do |values|
        values.id "an_id"
      end
      
      collection.members(:collection => a_collection) do |member, number|
        member.values do |values|
          values.id number
        end        
      end
    end
    
    hash = JSON.parse(json).extend(Methodize)
    
    assert_equal "an_id", hash.id
    assert_equal 1      , hash.members.first.id
    assert_equal 4      , hash.members.size
  end
  
  def test_collection_set_on_members_only_one
    obj = { :foo => "bar" }
    a_collection = [1]
    json = Hypertemplate::Builder::Json.build(obj) do |collection|
      collection.values do |values|
        values.id "an_id"
      end
      
      collection.members(:collection => a_collection) do |member, number|
        member.values do |values|
          values.id number
        end        
      end
    end
    
    hash = JSON.parse(json).extend(Methodize)
    
    assert_equal "an_id", hash.id
    assert_equal 1      , hash.members.first.id
    assert_equal 1      , hash.members.size
    assert hash.members.kind_of?(Array)
  end
  
  def test_raise_exception_for_not_passing_a_collection_as_parameter_to_members
    obj = 42
    
    assert_raise Hypertemplate::BuilderError do
      json = Hypertemplate::Builder::Json.build(obj) do |collection, number|
        collection.values do |values|
          values.id number
        end
      
        collection.members do |member, item|
          member.values do |values|
            values.id item
          end        
        end
      end
    end
  end

  def test_root_set_on_members
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    json = Hypertemplate::Builder::Json.build(obj) do |collection|
      collection.values do |values|
        values.id "an_id"
      end
      
      collection.members(:root => "foos") do |member, some_foos|
        member.values do |values|
          values.id some_foos[:foo]
        end        
      end
    end
    
    hash = JSON.parse(json).extend(Methodize)
    
    assert_equal "an_id", hash.id
    assert_equal "bar"  , hash.foos.first.id
    assert_equal 2      , hash.foos.size
  end
  
  def test_nesting_values_should_build_an_entire_tree
    obj = [{ :foo => "bar" }, { :foo => "zue" }]
    json = Hypertemplate::Builder::Json.build(obj) do |collection|
      collection.values do |values|
        values.body {
          values.face {
            values.eyes  "blue"
            values.mouth "large"
          }
          values.legs [
            { :right => { :fingers_count => 5 } }, { :left => { :fingers_count => 4 } }
          ]
        }
      end
    end
    
    hash = JSON.parse(json).extend(Methodize)
    
    assert_equal "blue" , hash.body.face.eyes
    assert_equal "large", hash.body.face.mouth
    assert_equal 2      , hash.body.legs.count
    assert_equal 4      , hash.body.legs.last.left.fingers_count
  end
  
  def test_build_single_link_in_collection_and_member
    obj = [{ :foo => "bar" }]
    json = Hypertemplate::Builder::Json.build(obj) do |collection|
      collection.values do |values|
        values.id "an_id"
      end
      
      collection.link 'self', "http://example.com/an_id"
      
      collection.members do |member, some_foos|
        member.values do |values|
          values.id some_foos[:foo]
        end
        
        member.link 'self', "http://example.com/an_id/#{some_foos[:foo]}"
      end
    end
    
    hash = JSON.parse(json).extend(Methodize)
    
    assert_equal "an_id", hash.id
    assert_equal "bar"  , hash.members.first.id
    assert hash.members.kind_of?(Array)
    assert hash.link.kind_of?(Array)
    assert hash.members.first.link.kind_of?(Array)
  end

  def test_build_full_collection
    time = Time.now
    some_articles = [
      {:id => 1, :title => "a great article", :updated => time},
      {:id => 2, :title => "another great article", :updated => time}
    ]
    
    json = Hypertemplate::Builder::Json.build(some_articles) do |collection|
      collection.values do |values|
        values.id      "http://example.com/json"
        values.title   "Feed"
        values.updated time

        values.author { 
          values.name  "John Doe"
          values.email "joedoe@example.com"
        }
        
        values.author { 
          values.name  "Foo Bar"
          values.email "foobar@example.com"
        }
      end
      
      collection.link("next"    , "http://a.link.com/next")
      collection.link("previous", "http://a.link.com/previous")
      
      collection.members(:root => "articles") do |member, article|
        member.values do |values|
          values.id      "uri:#{article[:id]}"                   
          values.title   article[:title]
          values.updated article[:updated]              
        end
        
        member.link("image", "http://example.com/image/1")
        member.link("image", "http://example.com/image/2", :type => "application/json")
      end
    end

    hash = JSON.parse(json).extend(Methodize)
    
    assert_equal "John Doe"               , hash.author.first.name
    assert_equal "foobar@example.com"     , hash.author.last.email
    assert_equal "http://example.com/json", hash.id
    
    assert_equal "http://a.link.com/next" , hash.link.first.href
    assert_equal "next"                   , hash.link.first.rel
    assert_equal "application/json"       , hash.link.last.type
    
    assert_equal "uri:1"                      , hash.articles.first.id
    assert_equal "a great article"            , hash.articles.first.title
    assert_equal "http://example.com/image/1" , hash.articles.last.link.first.href
    assert_equal "image"                      , hash.articles.last.link.first.rel
    assert_equal "application/json"           , hash.articles.last.link.last.type
  end

  def test_build_full_member
    time = Time.now
    an_article = {:id => 1, :title => "a great article", :updated => time}
    
    json = Hypertemplate::Builder::Json.build(an_article, :root => "article") do |member, article|
      member.values do |values|
        values.id      "uri:#{article[:id]}"           
        values.title   article[:title]
        values.updated article[:updated]
        
        values.domain("xmlns" => "http://a.namespace.com") {
          member.link("image", "http://example.com/image/1")
          member.link("image", "http://example.com/image/2", :type => "application/atom+xml")
        }
      end
      
      member.link("image", "http://example.com/image/1")
      member.link("image", "http://example.com/image/2", :type => "application/json")                                
    end
    
    hash = JSON.parse(json).extend(Methodize)
        
    assert_equal "uri:1"                      , hash.article.id
    assert_equal "a great article"            , hash.article.title
    assert_equal "http://example.com/image/1" , hash.article.link.first.href
    assert_equal "image"                      , hash.article.link.first.rel
    assert_equal "application/json"           , hash.article.link.first.type
    
    assert_equal "http://example.com/image/1" , hash.article.domain.link.first.href
    assert_equal "image"                      , hash.article.domain.link.first.rel
    assert_equal "application/json"           , hash.article.domain.link.first.type
    assert_equal "http://a.namespace.com"     , hash.article.domain.xmlns
  end
end



class Hypertemplate::Builder::JsonLambdaTest < Test::Unit::TestCase
  
  def json_build_and_parse(obj = {}, options = {}, &block)
    block ||= lambda {}
    json = Hypertemplate::Builder::Json.build_dsl(obj, options, &block)
    JSON.parse(json).extend(Methodize)
  end

  def test_accepts_custom_values
    json = json_build_and_parse do
      name "david"
    end

    assert_equal "david", json["name"]
  end

  def test_supports_any_attribute_by_using_the_write_method
    json = json_build_and_parse do
      write :to_s , "22"
    end
    
    assert_equal "22", json["to_s"]
  end
  
  def test_id_method_is_also_accepted
    json = json_build_and_parse do
      id  "22"
    end
  
    assert_equal "22", json["id"]
  end
  
  def test_allows_iterating_over_a_collection
    items = [{ :name => "pencil" }]
    json = json_build_and_parse do
      each(items) do |item|
        name item[:name]
      end
    end
  
    assert_equal "pencil"  , json["members"][0]["name"]
  end

  def test_allows_iterating_over_a_collection_of_strings
    items = ["pencil", "eraser"]
    json = json_build_and_parse do
      items.each do |item|
        name item
      end
    end
  
    assert_equal "pencil"  , json["name"][0]
    assert_equal "eraser"  , json["name"][1]
  end
  
  def test_allows_collection_custom_member_name
    items = [{ :name => "pencil" }]
    json = json_build_and_parse do
      each(items, :root => "item") do |item|
        name item[:name]
      end
    end
  
    assert_equal "pencil"  , json["item"][0]["name"]
  end
  
  def test_allows_typical_usage_of_a_collection
    items = [{ :name => "pencil" }, { :name => "eraser"}]
    json = json_build_and_parse do
      items {
        each(items, :root => "item") do |item|
          name item[:name]
        end
      }
    end
  
    assert_equal "pencil"  , json["items"]["item"][0]["name"]
    assert_equal "eraser"  , json["items"]["item"][1]["name"]
  end
  
  def test_supports_custom_root_with_collections
    items = [{ :name => "pencil" }, { :name => "eraser"}]
    json = json_build_and_parse({}, :root => "items") do
      each(items, :root => "item") do |item|
        name item[:name]
      end
    end
  
    assert_equal "pencil"  , json["items"]["item"][0]["name"]
    assert_equal "eraser"  , json["items"]["item"][1]["name"]
  end
  
  def test_uses_outside_scope_when_passing_an_arg_to_the_builder
    helper = Object.new
    def helper.name
      "guilherme"
    end
    json = json_build_and_parse(helper) do |s|
      name s.name
    end
  
    assert_equal "guilherme", json["name"]
  end
  
  def test_uses_externally_declared_objects_if_accessible
    obj = { :category => "esporte" }
    json = json_build_and_parse do |s|
      categoria obj[:category]
    end
  
    assert_equal "esporte", json["categoria"]
  end
  
  def test_accepts_nested_elements
    json = json_build_and_parse do
      body {
        face {
          eyes  "blue"
          mouth "large"
        }
      }
    end
  
    assert_equal "blue" , json["body"]["face"]["eyes"]
    assert_equal "large", json["body"]["face"]["mouth"]
  end
  
  def test_supports_collection_with_all_internals
    time = Time.now
    some_articles = [
      {:id => 1, :title => "a great article", :updated => time},
      {:id => 2, :title => "another great article", :updated => time}
    ]
    
    json = json_build_and_parse do
        id      "http://example.com/json"
        title   "Feed"
        updated time

        author { 
          name  "John Doe"
          email "joedoe@example.com"
        }
        
        author { 
          name  "Foo Bar"
          email "foobar@example.com"
        }
      
      link("next"    , "http://a.link.com/next")
      link("previous", "http://a.link.com/previous")
      
      each(some_articles, :root => "articles") do |article|
        id      "uri:#{article[:id]}"                   
        title   article[:title]
        updated article[:updated]              
        
        link("image", "http://example.com/image/1")
        link("image", "http://example.com/image/2", :type => "application/json")
      end
    end
    
    assert_equal "John Doe"               , json.author.first.name
    assert_equal "foobar@example.com"     , json.author.last.email
    assert_equal "http://example.com/json", json.id
    
    assert_equal "http://a.link.com/next" , json.link.first.href
    assert_equal "next"                   , json.link.first.rel
    assert_equal "application/json"       , json.link.last.type
    
    assert_equal "uri:1"                      , json.articles.first["id"]
    assert_equal "a great article"            , json.articles.first.title
    assert_equal "http://example.com/image/1" , json.articles.last.link.first.href
    assert_equal "image"                      , json.articles.last.link.first.rel
    assert_equal "application/json"           , json.articles.last.link.last.type
  end
  
    def test_build_full_member
      time = Time.now
      an_article = {:id => 1, :title => "a great article", :updated => time}
      
      json = json_build_and_parse(nil, :root => "article") do
          id      "uri:#{an_article[:id]}"           
          title   an_article[:title]
          updated an_article[:updated]
          
          domain("xmlns" => "http://a.namespace.com") {
            link("image", "http://example.com/image/1")
            link("image", "http://example.com/image/2", :type => "application/atom+xml")
          }
        
        link("image", "http://example.com/image/1")
        link("image", "http://example.com/image/2", :type => "application/json")                                
      end
          
      assert_equal "uri:1"                      , json.article.id
      assert_equal "a great article"            , json.article.title
      assert_equal "http://example.com/image/1" , json.article.link.first.href
      assert_equal "image"                      , json.article.link.first.rel
      assert_equal "application/json"           , json.article.link.first.type
      
      assert_equal "http://example.com/image/1" , json.article.domain.link.first.href
      assert_equal "image"                      , json.article.domain.link.first.rel
      assert_equal "application/json"           , json.article.domain.link.first.type
      assert_equal "http://a.namespace.com"     , json.article.domain.xmlns
    end
  
end


