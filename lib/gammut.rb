module Gammut
  def self.update_usb_logger
    l = Logger.new(File.join(ROOT_PATH, UPDATE_USB_LOG))
    l.level = UPDATE_USB_LOG_LEVEL
    l
  end

  def self.probe_ttyUSB(devname)
    sleep(3)
    l = update_usb_logger
    l.info { "Probing #{devname} with `gammu identify`" }
    l.close
  end

  def self.unregister_ttyUSB(devname)
    sleep(0.5)
    l = update_usb_logger
    l.info { "Killing associated gammu-smsd process" }
    l.close
  end
end
