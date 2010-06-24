module Gammut
  module Runner
    def self.list_devices(argv, opts)
      config = Gammut.config
      devices = Gammut.devices
      devices.each do |d|
        puts "#{d.devname}: #{d.imei} #{d.imsi}"
      end
    end

    def self.list(argv, opts)
      config = Gammut.config
      services = Gammut.services
      services.each do |s|
        puts "#{s.oneline_info}"
      end
    end
  end
end
