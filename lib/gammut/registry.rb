module Gammut
  module Registry
    def self.find_devices(config, registry_path)
      devices = [ ]
      Dir[File.join(registry_path, 'ttyUSB*.yml')].sort.each do |yml_file|
        devices.push(Gammut::Device.new(YAML.load_file(yml_file)))
      end
      devices
    end

    def self.find_services(config)
      svcs = [ ]
      config['services'].each do |sk, sd|
        svcs.push(Gammut::Service.new(sk, sd))
      end
      svcs
    end
  end
end
