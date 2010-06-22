require 'timeout'
require 'yaml'
require 'logger'

module Gammut
  CUSTOM_CONFIG_FILE = <<CCF
[gammu]
synchronizetime=yes
port=%devname%
connection=at
CCF

  autoload :Runner, File.join(File.dirname(__FILE__), 'gammut/runner')

  def self.capture_and_log_errors(l, reraise = false, &block)
    begin
      yield
    rescue Exception => e
      l.error { "#{e.class.name}: #{e.message}\n#{e.backtrace.join("\n")}" }
      raise if reraise
    end
  end

  def self.update_usb_logger
    l = Logger.new(File.join(ROOT_PATH, UPDATE_USB_LOG))
    l.level = UPDATE_USB_LOG_LEVEL
    l
  end

  def self.probe_ttyUSB(devname)
    # sleep for a bit while, to let the USB device to properly initialize
    sleep(8)

    l = update_usb_logger
    capture_and_log_errors(l) do
      l.info { "Probing #{devname} with `gammu identify`..." }
      identify_data = gammu_identify(devname, l)
      unless identify_data.nil?
        register_devname(devname, identify_data, l)
      end
    end
  ensure
    l.close
  end

  def self.unregister_ttyUSB(devname)
    sleep(0.5)
    l = update_usb_logger
    capture_and_log_errors(l) do
      l.info { "Removing from registry #{devname}..." }
      unregister_devname(devname, l)
    end
  ensure
    l.close
  end

  def self.unregister_devname(devname, l)
    basen = File.basename(devname)
    yml_file_path = File.join(ROOT_PATH, 'var/registry', "#{basen}.yml")

    if File.exists?(yml_file_path)
      identify_data = YAML.load_file(yml_file_path)

      if identify_data.include?('IMEI')
        imei = identify_data['IMEI']
        imei_file_path = File.join(ROOT_PATH, 'var/registry', "imei_#{imei}.yml")

        File.delete(imei_file_path) if File.exists?(imei_file_path) rescue nil
      end

      # Create a symlink for the IMSI file
      if identify_data.include?('SIM IMSI')
        imsi = identify_data['SIM IMSI']
        imsi_file_path = File.join(ROOT_PATH, 'var/registry', "imsi_#{imsi}.yml")

        File.delete(imsi_file_path) if File.exists?(imsi_file_path) rescue nil
      end

      File.delete(yml_file_path) rescue nil
    end
  end

  def self.register_devname(devname, identify_data, l)
    basen = File.basename(devname)
    yml_file_path = File.join(ROOT_PATH, 'var/registry', "#{basen}.yml")
    File.open(yml_file_path, 'w') do |f|
      YAML.dump(identify_data, f)
    end

    l.info "Written registry: #{yml_file_path}"

    # Create a symlink for the IMEI file
    if identify_data.include?('IMEI')
      imei = identify_data['IMEI']
      imei_file_path = File.join(ROOT_PATH, 'var/registry', "imei_#{imei}.yml")

      File.delete(imei_file_path) if File.exists?(imei_file_path) rescue nil
      File.symlink(yml_file_path, imei_file_path)
    end

    # Create a symlink for the IMSI file
    if identify_data.include?('SIM IMSI')
      imsi = identify_data['SIM IMSI']
      imsi_file_path = File.join(ROOT_PATH, 'var/registry', "imsi_#{imsi}.yml")

      File.delete(imsi_file_path) if File.exists?(imsi_file_path) rescue nil
      File.symlink(yml_file_path, imsi_file_path)
    end
  end

  def self.gammu_identify(devname, l)
    basen = File.basename(devname)
    tmp_config_path = File.join(ROOT_PATH, "var", "#{basen}.config")

    ccf = "#{CUSTOM_CONFIG_FILE}"
    ccf.gsub!("%devname%", devname)
    File.open(tmp_config_path, 'w') { |f| f.write(ccf) }

    cmd = "#{GAMMU_BIN} -c #{tmp_config_path}"
    if GAMMU_BIN_LOG_ENABLE
      gammu_bin_log_path = File.join(ROOT_PATH, GAMMU_BIN_LOG_PATH)
      cmd += " -d textalldate -f #{gammu_bin_log_path}"
    end
    cmd += " identify"

    l.debug { "Exec #{cmd}" }

    identify_data = { }
    f = open("|#{cmd}")
    unless f.nil?
      # allow up to 90 secs. sometimes probing takes a while.
      tm = 90

      begin
        Timeout::timeout(tm) do
          while !f.eof?
            reply = f.gets.strip
            l.debug { "GOT: #{reply}" }

            # split, and do a lot of whitespace and quotes cleaning
            ikey, ival = reply.split(/\s+\:\s+/, 2)
            unless ival.nil?
              ival = ival.strip
              ival = $~[1] if ival =~ /\A\"(.+)\"\Z/
              unless ival.empty?
                identify_data[ikey.strip] = ival
              end
            end
          end
        end
      rescue Timeout::Error
        l.error { "Timeout! Unable to get identify response within #{tm} second(s)" }
      ensure
        f.close
      end
    else
      l.error { "Open-pipe cmd returned nil. Something is wrong" }
    end

    unless identify_data.empty?
      identify_data
    else
      l.error { "Unable to retrieve gammu identity information" }
      nil
    end
  end
end
