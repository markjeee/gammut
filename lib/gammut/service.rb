module Gammut
  class Service
    attr_reader :skey

    def initialize(skey, sdata)
      @skey = skey
      @sdata = sdata
    end

    def connected?
      !device.nil?
    end

    def auto_start?
      true
    end

    # write configuration file. overwriting any
    def configure
      devname = device.devname
      gsco = { 'service_name' => @skey }

      Gammut::Gammu.gammu_smsd_create_configuration(devname, gsco)
    end

    # start the service, if not started
    def start
      configure
      Gammut::Gammu.gammu_smsd_start(device.devname, @skey)
    end

    # stop the service if not available
    def stop
      Gammut::Gammu.gammu_smsd_stop(device.devname, @skey)
    end

    # check if the service is running
    def status
      Gammut::Gammu.gammu_smsd_status(device.devname, @skey)
    end

    def devname; device.devname; end
    def imei; device.imei; end
    def imsi; device.imsi; end

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
