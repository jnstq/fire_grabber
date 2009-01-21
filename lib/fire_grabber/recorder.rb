module FireGrabber
  class Recorder
    class_inheritable_hash :configuration
    self.configuration = {}
    self.configuration[:dvgrab_exeutable] = 'dvgrab'
    self.configuration[:output_file] = ''
    
    def start!
      raise "No output file specified"
    end
  end
end
