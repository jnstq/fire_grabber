require File.dirname(__FILE__) + '/../spec_helper'

describe FireGrabber::Recorder do

  before(:each) do
    FireGrabber::Recorder.configuration[:dvgrab_exeutable] = '/Users/jon/NetBeansProjects/fire_grabber/spec/support/dvgrab'
    @r = FireGrabber::Recorder.new
  end

  describe "settings" do
    it "should respond to configuration" do
      FireGrabber::Recorder.configuration.should be_kind_of(Hash)
    end
    
    it "should have standard setting for dvgrab executable" do
      FireGrabber::Recorder.configuration[:dvgrab_exeutable] = '/path/to/dvgrab'
      FireGrabber::Recorder.configuration[:dvgrab_exeutable].should eql('/path/to/dvgrab')
    end
    
  end

  describe "record" do
    
    it "should raise error when not output file is set" do
      @r.start!
    end
    
  end

end
