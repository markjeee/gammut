module Gammut
  module Registry
    def self.find_devices(config, registry_path)
      devices = [ ]
      Dir[File.join(registry_path, 'ttyUSB*.yml')].sort.each do |yml_file|
        devices.push(Gammut::Device.new(YAML.load_file(yml_file)))
      end
      devices
    end

    def self.find_service(service_name, config)
      if config['services'].include?(service_name)
        Gammut::Service.new(service_name, config['services'][service_name])
      else
        nil
      end
    end

    def self.find_services(config)
      svcs = [ ]
      config['services'].each do |sk, sd|
        svcs.push(Gammut::Service.new(sk, sd))
      end
      svcs
    end

    def self.unregister_devname(devname)
      basen = File.basename(devname)
      yml_file_path = File.join(Gammut.registry_path, "#{basen}.yml")

      if File.exists?(yml_file_path)
        identify_data = YAML.load_file(yml_file_path)

        if identify_data.include?('IMEI')
          imei = identify_data['IMEI']
          imei_file_path = File.join(Gammut.registry_path, "imei_#{imei}.yml")

          File.delete(imei_file_path) if File.exists?(imei_file_path) rescue nil
        end

        # Create a symlink for the IMSI file
        if identify_data.include?('SIM IMSI')
          imsi = identify_data['SIM IMSI']
          imsi_file_path = File.join(Gammut.registry_path, "imsi_#{imsi}.yml")

          File.delete(imsi_file_path) if File.exists?(imsi_file_path) rescue nil
        end

        File.delete(yml_file_path) rescue nil
      end

      yml_file_path
    end

    def self.register_devname(devname, identify_data)
      basen = File.basename(devname)
      yml_file_path = File.join(Gammut.registry_path, "#{basen}.yml")
      File.open(yml_file_path, 'w') do |f|
        YAML.dump(identify_data, f)
      end

      # Create a symlink for the IMEI file
      if identify_data.include?('IMEI')
        imei = identify_data['IMEI']
        imei_file_path = File.join(Gammut.registry_path, "imei_#{imei}.yml")

        File.delete(imei_file_path) if File.exists?(imei_file_path) rescue nil
        File.symlink(yml_file_path, imei_file_path)
      end

      # Create a symlink for the IMSI file
      if identify_data.include?('SIM IMSI')
        imsi = identify_data['SIM IMSI']
        imsi_file_path = File.join(Gammut.registry_path, "imsi_#{imsi}.yml")

        File.delete(imsi_file_path) if File.exists?(imsi_file_path) rescue nil
        File.symlink(yml_file_path, imsi_file_path)
      end

      yml_file_path
    end
  end
end
