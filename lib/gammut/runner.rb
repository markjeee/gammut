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

    def self.configure(argv, opts)
      config = Gammut.config
      service_name = argv[1]

      svc = Gammut::Registry.find_service(service_name, config)
      if !svc.nil?
        if svc.connected?
          config_file_path = svc.configure
          puts "configured: #{config_file_path}"
        else
          puts "not connected"
        end
      elsif service_name.nil?
        puts "please specify a service to configure"
      else
        puts "unknown service: #{service_name}"
      end
    end

    def self.start(argv, opts)
      config = Gammut.config
      service_name = argv[1]

      svc = Gammut::Registry.find_service(service_name, config)
      if !svc.nil?
        if svc.connected?
          pid = svc.status
          if pid.nil?
            pid = svc.start
            if pid.nil?
              puts "ERR gammu probably crashed, see corresponding gammu-smsd log file"
            else
              puts "running with pid #{pid}"
            end
          else
            puts "ERR gammut is already running at #{pid}"
          end
        else
          puts "not connected"
        end
      elsif service_name.nil?
        puts "please specify a service to start"
      else
        puts "unknown service: #{service_name}"
      end
    end

    def self.stop(argv, opts)
      config = Gammut.config
      service_name = argv[1]

      svc = Gammut::Registry.find_service(service_name, config)
      if !svc.nil?
        if svc.connected?
          pid = svc.status
          unless pid.nil?
            svc.stop
            puts "stopped #{pid}"
          else
            puts "ERR gammut not running"
          end
        else
          puts "not connected"
        end
      elsif service_name.nil?
        puts "please specify a service to stop"
      else
        puts "unknown service: #{service_name}"
      end
    end

    def self.status(argv, opts)
      config = Gammut.config
      service_name = argv[1]

      svc = Gammut::Registry.find_service(service_name, config)
      if !svc.nil?
        if svc.connected?
          pid = svc.status
          if pid.nil?
            puts "gammu-smsd not running"
          else
            puts "running with pid #{pid}"
          end
        else
          puts "not connected"
        end
      elsif service_name.nil?
        puts "please specify a service to check status"
      else
        puts "unknown service: #{service_name}"
      end
    end
  end
end
