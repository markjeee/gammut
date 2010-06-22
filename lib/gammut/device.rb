module Gammut
  class Device
    attr_reader :devname
    attr_reader :imei
    attr_reader :imsi

    def initialize(config)
      @config = config
      parse_config
    end

    protected

    # ---
    # Model: unknown (E1552)
    # SIM IMSI: "515021508997248"
    # Firmware: 11.608.13.10.158
    # Manufacturer: huawei
    # IMEI: "358812032421899"
    def parse_config
      @devname = @config['devname']
      @imsi = @config['SIM IMSI']
      @imei = @config['IMEI']
    end
  end
end
