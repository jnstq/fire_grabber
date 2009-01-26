require File.dirname(__FILE__) + '/../spec_helper'

describe FireGrabber::Recorder do

  before(:each) do
    FireGrabber::Recorder.configure do |config|
      config.output_file = '/path/to/file'
      config.line_ending = "\n"
      config.dvgrab_exeutable = File.expand_path("#{File.dirname(__FILE__)}/../support/dvgrab")
    end
    @r = FireGrabber::Recorder.new
  end

  describe "logger" do

    it "should create a logger object if log_file is specified" do
      FireGrabber::Recorder.configure do |config|
        config.log_file = 'fire_grabber.log'
      end
      FireGrabber::Recorder.new.logger.should be_kind_of(Logger)
    end
  end

  describe "settings" do

    it "should respond to configuration" do
      FireGrabber::Recorder.configuration.should be_kind_of(Hash)
    end

    it "should have standard setting for dvgrab executable" do
      FireGrabber::Recorder.configuration[:dvgrab_exeutable] = '/path/to/dvgrab'
      FireGrabber::Recorder.configuration[:dvgrab_exeutable].should eql('/path/to/dvgrab')
    end

    it "should have default dvgrab params" do
      FireGrabber::Recorder.configuration[:dvgrab_args].should eql('-showstatus -noavc -f dv1')
    end

    it "should have default value for line break of output from dvgrab" do
      FireGrabber::Recorder.configuration[:line_ending] = "\r"
    end

    it "should yield configure structur" do
      FireGrabber::Recorder.configure do |config|
        config.should be_a_kind_of(OpenStruct)
      end
    end

    it "should allow changes in configure block" do
      FireGrabber::Recorder.configure do |config|
        config.output_file = "/other/output/file"
      end
      FireGrabber::Recorder.configuration[:output_file].should eql("/other/output/file")
    end

  end

  describe "record" do

    it "should raise error when not output file is set" do
      FireGrabber::Recorder.configuration[:output_file] = nil
      lambda{ @r.start! }.should raise_error
    end

    it "should raise if it's already started" do
      @r.start!
      lambda{ @r.start! }.should raise_error
    end

    it "should start recording" do
      @r.start!
      @r.should be_recording
    end

    it "should stop recording" do
      @r.stop!
      @r.should_not be_recording
    end

    it "should nil all attributes on start" do
      @r.instance_eval { @filename = @frames = @size = @timecode = @started_at = @ended_at = "some value" }
      @r.start!
      [:filename, :frames, :size, :timecode, :ended_at].each do |attr|
        @r.send(attr).should eql(nil)
      end
    end

    describe "status" do
      it "should return status hash on stop" do
        @r.start!
        @r.stop!.should be_kind_of(Hash)
      end
    end

  end

  describe "elapsed time" do

    before(:each) do
      @r.stub!(:run_dvgrab)
      @r.stub!(:kill_dvgrab)
      @r.stub!(:capture_output)
      @r.stub!(:stop_capture_output)
    end

    it "should set started at" do
      @r.start!
      @r.started_at.to_s(:db).should eql(Time.now.to_s(:db))
    end

    it "should set ended at" do
      @r.stub!(:dvgrab_running?).and_return(true)
      @r.stop!
      @r.ended_at.to_s(:db).should eql(Time.now.to_s(:db))
    end

    it "should return elapsed time based on curren time unless ended" do
      @r.started_at = Time.now - 1.hour
      @r.elapsed_time.to_s(:time).should eql("01:00")
    end

    it "should return elapsed time based on ended at" do
      @r.started_at = Time.now - 1.hour
      @r.ended_at = Time.now + 2.hour
      @r.elapsed_time.to_s(:time).should eql("03:00")
    end

  end

  describe "parse dvgrab output" do
    
    it "should get filename" do
      @r.parse(%Q["/path/to/file.avi":    72.00 MiB  1800 frames timecode 00:01:12.00 date 2009-01-21 21:06:20])
      @r.filename.should eql("/path/to/file.avi")
    end

    it "should get size" do
      @r.parse(%Q["/path/to/file.avi":    72.00 MiB  1800 frames timecode 00:01:12.00 date 2009-01-21 21:06:20])
      @r.size.should eql("72.00")
    end

    it "should get frames" do
      @r.parse(%Q["/path/to/file.avi":    72.00 MiB  1800 frames timecode 00:01:12.00 date 2009-01-21 21:06:20])
      @r.frames.should eql("1800")
    end

    it "should get timecode" do
      @r.parse(%Q["/path/to/file.avi":    72.00 MiB  1800 frames timecode 00:01:12.00 date 2009-01-21 21:06:20])
      @r.timecode.should eql("00:01:12.00")
    end

  end

end
