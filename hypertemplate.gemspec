require File.join(File.dirname(__FILE__), "lib", "hypertemplate", "version.rb")

Gem::Specification.new do |s|
  s.name          = "hypertemplate"
  s.version       = Hypertemplate::VERSION.to_s
  s.platform      = Gem::Platform::RUBY
  s.summary       = "A template engine that generates hypermedia enbabled media types representations"

  s.require_paths = ['lib']
  s.files         = Dir["{lib/**/*.rb,README.md,LICENSE,test/**/*,script/*}"]

  s.author        = "Guilherme Silveira & Hypertemplate & Tokamak & Restfulie team"
  s.email         = "restfulie@googlegroups.com"
  s.homepage      = "http://github.com/caelum/hypertemplate"

  s.add_dependency('json_pure')
  s.add_dependency('nokogiri')

  s.add_development_dependency('ruby-debug')
  s.add_development_dependency('methodize')
  s.add_development_dependency('rack',"~>1.2")
  s.add_development_dependency('rack-test')
  s.add_development_dependency('rack-conneg')
  s.add_development_dependency('tilt',"~>1.2")
  s.add_development_dependency('sinatra',"~>1.1")
  s.add_development_dependency('rails',">=2.3.2")
end
