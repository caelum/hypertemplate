$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__))

# Dependencies
require "rubygems"
require "bundler/setup"

module Hypertemplate
end

require "hypertemplate/errors"
require "hypertemplate/recipes"
require "hypertemplate/builder"
require "hypertemplate/registry"
require "hypertemplate/hook"
