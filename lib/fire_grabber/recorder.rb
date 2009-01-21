require 'rubygems'
require 'activesupport'
require 'ostruct'

module FireGrabber
  class Recorder
    class_inheritable_hash :configuration
    self.configuration = {}
    
    def self.configure
      yield config = OpenStruct.new(configuration)
      configuration.merge!(config.marshal_dump)
    end
    
    # Default settings
    configure do |config|
      config.dvgrab_exeutable = 'dvgrab'
      config.dvgrab_args = '-showstatus -noavc -f dv1'
      config.output_file = ''
      config.line_ending = "\r"      
    end

    attr_accessor :filename, :frames, :size, :timecode, :started_at, :ended_at

    def initialize
      @dvgrab_pipe = @capture_output = nil
      Signal.trap("CHLD") do
        puts "dvgrab proccses terminated"
        @dvgrab_pipe = nil
      end
    end

    def start!
      raise "No output file specified" unless configuration[:output_file].present?
      raise "Already recording" if recording?      
      nullify_accessors!
      run_dvgrab
      capture_output
      @started_at = Time.now
    end

    def stop!
      return unless recording?
      kill_dvgrab
      stop_capture_output
      @ended_at = Time.now
    end

    def recording?
      @dvgrab_pipe
    end
    
    def elapsed_time
      return unless @started_at
      Time.now.at_beginning_of_day + elapsed_in_seconds
    end
    
    def parse(dvgrab_output)
      if dvgrab_output =~ /"([.a-zA-Z\/]*)":\s+(.*)\s+MiB\s+(\d+)\s+frames\s+timecode\s+(.*)\s+date/
        @filename, @size, @frames, @timecode = $1, $2, $3, $4
      end
    end

    private
    
    def run_dvgrab
      @dvgrab_pipe = IO.popen(dvgrab_command)      
    end
    
    def kill_dvgrab
      Process.kill("HUP", @dvgrab_pipe.pid)
      @dvgrab_pipe.close
      @dvgrab_pipe = nil      
    end
    
    def capture_output
      @capture_output = Thread.new do
        @dvgrab_pipe.each(configuration[:line_ending]) do |line|
          parse(line)
        end
      end      
    end
    
    def stop_capture_output
      @capture_output.kill
    end
    
    def nullify_accessors!
      @filename = nil
      @frames = nil
      @size = nil
      @timecode = nil
      @started_at = nil
      @ended_at = nil
    end

    def dvgrab_command
      "#{configuration[:dvgrab_exeutable]} #{configuration[:dvgrab_args]} #{configuration[:output_file]} 2>&1"
    end
    
    def elapsed_in_seconds
      return Time.now - @started_at unless @ended_at
      @ended_at - @started_at
    end    
  end
end

if __FILE__ == $PROGRAM_NAME
  FireGrabber::Recorder.configure do |config|
    config.dvgrab_exeutable = '/Users/jon/code/test/fire_grabber/spec/support/dvgrab'
    config.output_file = '/path/to/file'
    config.line_ending = "\n"
  end
  
  r = FireGrabber::Recorder.new
  r.start!
  sleep 10
  r.stop!
end
