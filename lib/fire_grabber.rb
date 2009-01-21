require 'rubygems'
require 'activesupport'

$: << File.expand_path(File.dirname(__FILE__))

module FireGrabber
  autoload :Recorder, "fire_grabber/recorder"
end