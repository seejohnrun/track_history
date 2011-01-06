require File.dirname(__FILE__) + '/../../lib/track_history'
require 'rubygems'
require 'track_history'

ActiveRecord::Base.establish_connection(:adapter => 'mysql', :database => 'track_history')
