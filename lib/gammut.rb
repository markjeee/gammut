require 'timeout'
require 'yaml'
require 'logger'

module Gammut
  autoload :Runner, File.join(File.dirname(__FILE__), 'gammut/runner')
  autoload :Registry, File.join(File.dirname(__FILE__), 'gammut/registry')
  autoload :Gammu, File.join(File.dirname(__FILE__), 'gammut/gammu')
  autoload :Service, File.join(File.dirname(__FILE__), 'gammut/service')
  autoload :Device, File.join(File.dirname(__FILE__), 'gammut/device')

  def self.root_path; @root_path; end
  def self.root_path=(rp); @root_path = rp; end
  def self.logger; @logger; end
  def self.logger=(l); @logger = l; end

  def self.registry_path
    File.join(root_path, GAMMUT_REGISTRY_PATH)
  end

  def self.gammu_config_path
    File.join(root_path, GAMMU_CONFIG_PATH)
  end

  def self.config
    if defined?(@config)
      @config
    else
      @config = YAML.load_file(File.join(root_path, GAMMUT_CONFIG_PATH))
    end
  end

  def self.init(root_path, logger)
    self.root_path = root_path
    self.logger = logger
  end

  def self.devices
    if defined?(@devices)
      @devices
    else
      @devices = Gammut::Registry.find_devices(config, registry_path)
    end
  end

  def self.services
    if defined?(@services)
      @services
    else
      @services = Gammut::Registry.find_services(config)
    end
  end

  def self.capture_and_log_errors(reraise = false, &block)
    begin
      yield
    rescue Exception => e
      logger.error { "#{e.class.name}: #{e.message}\n#{e.backtrace.join("\n")}" }
      raise if reraise
    end
  end

  def self.gammut_logger(root_path = nil)
    l = Logger.new(File.join(root_path || ROOT_PATH, GAMMUT_LOG))
    l.level = GAMMUT_LOG_LEVEL
    l
  end

  def self.update_usb_logger(root_path = nil)
    l = Logger.new(File.join(root_path || ROOT_PATH, UPDATE_USB_LOG))
    l.level = UPDATE_USB_LOG_LEVEL
    l
  end

  def self.probe_ttyUSB(devname)
    # sleep for a bit while, to let the USB device to properly initialize
    sleep(8)

    capture_and_log_errors do
      logger.info { "Probing #{devname} with `gammu identify`..." }

      identify_data = Gammut::Gammu.gammu_identify(devname)
      unless identify_data.nil?
        yml_file_path = Gammut::Registry.register_devname(devname, identify_data)
        logger.info "Written registry: #{yml_file_path}"
      end
    end
  end

  def self.unregister_ttyUSB(devname)
    sleep(0.5)

    capture_and_log_errors do
      logger.info { "Removing from registry #{devname}" }
      Gammut::Registry.unregister_devname(devname)
    end
  end
end
