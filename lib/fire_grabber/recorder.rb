module FireGrabber
  class Recorder
    def self.configuration
      @@configuration ||= {
        :dvgrab_exeutable => 'dvgrab'
      }
    end
  end
end
