require 'rubygems'
require 'activesupport'
require 'ostruct'

Time::DATE_FORMATS[:timecode] = "%H:%M:%S.00"

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

    attr_accessor :filename, :frames, :size, :timecode, :started_at, :ended_at, :logger, :terminated_unexpected, :stalled

    def initialize
      @logger = Logger.new(configuration[:log_file] || STDOUT)
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      @dvgrab_pipe = @capture_output = nil
      Signal.trap("CHLD") do
        logger.info("Dvgrab proccses terminated")
        @terminated_unexpected = true unless @ended_at
        @dvgrab_pipe = nil
      end
      heartbeat
    end

    def start!
      raise "No output file specified" unless configuration[:output_file].present?
      raise "Dvgrab already running" if dvgrab_running?      
      nullify_accessors!
      run_dvgrab
      capture_output
      @started_at = Time.now
    end

    def stop!
      return unless dvgrab_running?
      @ended_at = Time.now
      kill_dvgrab
      stop_capture_output
      attributes
    end

    def recording?
      !! @dvgrab_pipe
    end
    
    def dvgrab_running?
      @dvgrab_pipe
    end
    
    def stalled?
      @dvgrab_pipe && @stalled
    end
    
    def terminated_unexpected?
      @terminated_unexpected
    end
    
    def elapsed_time
      return unless @started_at
      Time.now.at_beginning_of_day + duration.seconds
    end
    
    def duration
      return Time.now - @started_at unless @ended_at
      @ended_at - @started_at
    end        
    
    def parse(dvgrab_output)
      if dvgrab_output =~ recording_info
        @filename, @size, @frames, @timecode = $1, $2, $3, $4
      end
    end
    
    def attributes
      {:filename => @filename, :started_at => @started_at, :ended_at => @ended_at, :frames => @frames, :size => @size, :timecode => @timecode, :duration => (elapsed_time && elapsed_time.to_s(:timecode)) }
    end    

    private
    
    def heartbeat
      @last_checked_frames = nil
      Thread.new do
        loop do
          @stalled = @frames == @last_checked_frames
          @last_checked_frames = @frames
          sleep 1
        end
      end      
    end
    
    def recording_info
      /"([.\w\/]*)":\s+(.*)\s+MiB\s+(\d+)\s+frames\s+timecode\s+(.*)\s+date/
    end
    
    def run_dvgrab
      logger.info("Starting #{dvgrab_command}")
      @dvgrab_pipe = IO.popen(dvgrab_command)      
    end
    
    def kill_dvgrab
      logger.info("Killing dvgrab proccess #{@dvgrab_pipe.pid}")
      Process.kill("INT", @dvgrab_pipe.pid)
      @dvgrab_pipe.close if @dvgrab_pipe
      @dvgrab_pipe = nil      
    end
    
    def capture_output
      logger.info("Starting capture thread")
      @capture_output = Thread.new do
        @dvgrab_pipe.each(configuration[:line_ending]) do |line|
          line.strip!
          if line.present?            
            logger.info(line)
            parse(line)
          end
        end
      end      
    end
    
    def stop_capture_output
      logger.info("Stopping capture thread")
      @capture_output.kill
    end
    
    def nullify_accessors!
      @stalled = nil
      @filename = nil
      @frames = nil
      @size = nil
      @timecode = nil
      @started_at = nil
      @ended_at = nil
      @terminated_unexpected = nil
    end

    def dvgrab_command
      "#{configuration[:dvgrab_exeutable]} #{configuration[:dvgrab_args]} #{configuration[:output_file]} 2>&1"
    end
    
  end
end

if __FILE__ == $PROGRAM_NAME
  FireGrabber::Recorder.configure do |config|
    config.dvgrab_exeutable = File.expand_path("#{File.dirname(__FILE__)}/../../spec/support/dvgrab")
    config.output_file = '/path/to/file_name/'
    config.line_ending = "\n"
  end
  
  r = FireGrabber::Recorder.new
  r.start!
  sleep 10
  r.stop!
end
