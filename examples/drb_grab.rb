require 'rubygems'
require 'drb'
require "#{File.dirname(__FILE__)}/../lib/fire_grabber"
 
FireGrabber::Recorder.configure do |config|
  config.output_file = File.expand_path("#{File.dirname(__FILE__)}/captured")
  # This need to be changed
  config.dvgrab_exeutable = File.expand_path("#{File.dirname(__FILE__)}/../spec/support/dvgrab")
  config.dvgrab_args = '-showstatus -noavc'
  # You propery want to log the output from file_grabber and dvgrab
  config.log_file = File.expand_path("#{File.dirname(__FILE__)}/../../video_producer/log/development.log")
end
 
DRb.start_service("druby://localhost:7777", FireGrabber::Recorder.new)
DRb.thread.join