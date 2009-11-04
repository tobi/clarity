$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'eventmachine'
require 'evma_httpserver'
require 'yaml'
require 'base64'
require 'clarity/server'
require 'clarity/commands/command_builder'
require 'clarity/commands/tail_command_builder'
require 'clarity/parsers/time_parser'
require 'clarity/parsers/hostname_parser'
require 'clarity/parsers/shop_parser'
require 'clarity/renderers/log_renderer'

module Clarity
  VERSION = '0.9.1'  
  
  Templates = File.dirname(__FILE__) + '/../views'
  Public    = File.dirname(__FILE__) + '/../public'
end
