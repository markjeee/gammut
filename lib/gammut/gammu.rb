module Gammut
  module Gammu
  CUSTOM_CONFIG_FILE = <<CCF
[gammu]
synchronizetime=yes
port=%devname%
connection=at
CCF

    def self.gammu_identify(devname)
      logger = Gammut.logger

      basen = File.basename(devname)
      tmp_config_path = File.join(Gammut.gammu_config_path, "#{basen}.config")

      ccf = "#{CUSTOM_CONFIG_FILE}"
      ccf.gsub!("%devname%", devname)
      File.open(tmp_config_path, 'w') { |f| f.write(ccf) }

      cmd = "#{GAMMU_BIN} -c #{tmp_config_path}"
      if GAMMU_BIN_LOG_ENABLE
        gammu_bin_log_path = File.join(ROOT_PATH, GAMMU_BIN_LOG_PATH)
        cmd += " -d textalldate -f #{gammu_bin_log_path}"
      end
      cmd += " identify"

      logger.debug { "Exec #{cmd}" }

      identify_data = { }
      f = open("|#{cmd}")
      unless f.nil?
        # allow up to 90 secs. sometimes probing takes a while.
        tm = 90

        begin
          Timeout::timeout(tm) do
            while !f.eof?
              reply = f.gets.strip
              logger.debug { "GOT: #{reply}" }

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
          logger.error { "Timeout! Unable to get identify response within #{tm} second(s)" }
        ensure
          f.close
        end
      else
        logger.error { "Open-pipe cmd returned nil. Something is wrong" }
      end

      unless identify_data.empty?
        # add additional data, not returned by gammut identify
        identify_data['devname'] = devname
        identify_data
      else
        logger.error { "Unable to retrieve gammu identity information" }
        nil
      end
    end
  end
end
