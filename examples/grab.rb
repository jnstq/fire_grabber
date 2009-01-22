require 'rubygems'
require "#{File.dirname(__FILE__)}/../lib/fire_grabber"
 
FireGrabber::Recorder.configure do |config|
  config.output_file = File.expand_path("#{File.dirname(__FILE__)}/captured")
  config.dvgrab_exeutable = File.expand_path("#{File.dirname(__FILE__)}/../spec/support/dvgrab")
  config.dvgrab_args = '-showstatus -noavc'
  config.line_ending = "\n" # Make sure that this is \r when running the real dvgrab
  config.log_file = File.expand_path("#{File.dirname(__FILE__)}/file_grabber.log")
end
 
r= FireGrabber::Recorder.new
r.start!
sleep 5
puts r.elapsed_time
puts r.filename
r.stop!