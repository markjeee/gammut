module Gammut
  class Service
    attr_reader :skey

    def initialize(skey, sdata)
      @skey = skey
      @sdata = sdata
    end

    # write configuration file. overwriting any
    def configure
    end

    # start the service, if not started
    def start
    end

    # stop the service if not available
    def stop
    end

    # check if the service is running
    def status
    end

    def device
      if defined?(@device)
        @device
      else
        Gammut.devices.each do |d|
          if @sdata.include?('IMSI') && d.imsi == @sdata['IMSI'].to_s
            @device = d
            break
          elsif @sdata.include?('IMEI') && d.imei == @sdata['IMEI'].to_s
            @device = d
            break
          else
            @device = nil
          end
        end

        @device
      end
    end

    def device_match
      if @sdata.include?('IMSI')
        "IMSI #{@sdata['IMSI']}"
      elsif @sdata.include?('IMEI')
        "IMEI #{@sdata['IMEI']}"
      else
        nil
      end
    end

    def oneline_info
      if device.nil?
        "#{@skey}: device not connected (#{device_match})"
      else
        "#{@skey}: #{device.devname} IMEI: #{device.imei} IMSI: #{device.imsi}"
      end
    end
  end
end
