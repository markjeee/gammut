require 'open3'

module Gammut
  module Gammu
    GAMMU_CONFIG_FILE = <<GCF
[gammu]
synchronizetime=yes
port=%devname%
connection=at
GCF

    GAMMU_SMSD_CONFIG_FILE = <<GSCF
[gammu]
port = %devname%
connection = at
synchronizetime = yes

[smsd]
PhoneID = %service_name%
DebugLevel = 225
Service = mysql
user = %db_user%
password = %db_password%
PC = %db_host_with_port%
Database = %db_database%
LogFile = %service_log_path%
CommTimeout = 15
SendTimeout = 30
MaxRetries = 6
CheckSecurity = 0
CheckBattery = 0
GSCF

    GAMMU_SMSD_CONFIG_REQUIRED_OPTIONS = %w{ service_name }
    GAMMU_SMSD_CONFIG_OPTIONAL_OPTIONS = %w{ db_user db_password db_host_with_port db_database service_log_path }

    def self.gammu_smsd_create_configuration(devname, config_options = { })
      copts = config_options.clone
      copts['devname'] = devname

      GAMMU_SMSD_CONFIG_REQUIRED_OPTIONS.each do |o|
        raise "Missing #{o} from config_options" unless config_options.include?(o)
      end
      service_name = copts['service_name']
      config_file_path = File.join(Gammut.root_path, "var/#{service_name}.gammu-smsd.config")

      GAMMU_SMSD_CONFIG_OPTIONAL_OPTIONS.each do |o|
        case o
        when 'db_user'
          unless copts.include?(o)
            copts[o] = 'root'
          end
        when 'db_password'
          unless copts.include?(o)
            copts[o] = ''
          end
        when 'db_host_with_port'
          unless copts.include?(o)
            copts[o] = '127.0.0.1:3306'
          end
        when 'db_database'
          unless copts.include?(o)
            copts[o] = 'smsd'
          end
        when 'service_log_path'
          unless copts.include?(o)
            copts[o] = File.join(Gammut.root_path, "log/#{service_name}.gammu-smsd.log")
          end
        else
          raise "Unsupported optional option key #{o}"
        end
      end

      gscf = "#{GAMMU_SMSD_CONFIG_FILE}"
      copts.each do |ok, ov|
        gscf.gsub!("%#{ok}%", ov)
      end
      File.open(config_file_path, 'w') { |f| f.write(gscf) }

      config_file_path
    end

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

      identify_data = { }
      open_system(cmd) do |reply|
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

      unless identify_data.empty?
        # add additional data, not returned by gammut identify
        identify_data['devname'] = devname
        identify_data
      else
        logger.error { "Unable to retrieve gammu identity information" }
        nil
      end
    end

    # gammu-smsd -d -c var/globe1.gammu-smsd.config -p var/run/globe1.gammu-smsd.pid
    def self.gammu_smsd_start(devname, service_name)
      logger = Gammut.logger

      pid_file = File.join(Gammut.root_path, "var/run/#{service_name}.gammu-smsd.pid")
      config_file_path = File.join(Gammut.root_path, "var/#{service_name}.gammu-smsd.config")

      cmd = "#{GAMMU_SMSD_BIN} -d -c #{config_file_path} -p #{pid_file}"
      open_system(cmd)

      sleep(1)
      if File.exists?(pid_file)
        pid = File.read(pid_file).strip
        logger.info "gammu-smsd service_name = #{service_name} devname = #{devname} found running at #{pid}"
        pid
      else
        logger.warn "recently executed gammu-smsd probably crashed service_name = #{service_name} devname = #{devname}"
        nil
      end
    end

    def self.gammu_smsd_stop(devname, service_name)
      logger = Gammut.logger
      pid_file = File.join(Gammut.root_path, "var/run/#{service_name}.gammu-smsd.pid")

      pid = read_pid_file(pid_file)
      unless pid.nil?
        tm = 10; step = 0.5

        logger.info "Sending 'TERM' to running gammu-smsd with pid #{pid} (#{tm} sec(s) tm)"
        Process.kill('TERM', pid)
        until !process_running?(pid)
          sleep(step)
          (tm -= step) > 0 && next

          logger.warn "Sending 'KILL' (force) to running gammu-smsd with #{pid}"
          Process.kill('KILL', pid)
          sleep(step)
        end

        pid
      else
        nil
      end
    end

    def self.gammu_smsd_status(devname, service_name)
      logger = Gammut.logger

      pid_file = File.join(Gammut.root_path, "var/run/#{service_name}.gammu-smsd.pid")

      if File.exists?(pid_file)
        pid = File.read(pid_file).strip.to_i

        if pid > 0
          begin
            pid = nil if Process.getpgid(pid) == -1
          rescue Errno::ESRCH
            pid = nil
          end

          if pid.nil?
            logger.warn "Found an existing pid file with pid #{pid} but it looks orphaned. Deleting."
            File.delete(pid_file)
          end
        else
          pid = nil
          File.delete(pid_file)
        end

        pid
      else
        nil
      end
    end

    def self.process_running?(pid)
      Process.getpgid(pid) != -1
    rescue Errno::ESRCH
      false
    end

    def self.read_pid_file(pid_file)
      if File.exists?(pid_file)
        File.read(pid_file).strip.to_i
      else
        nil
      end
    end

    def self.open_system(cmd, &block)
      logger = Gammut.logger
      reply = [ ]

      logger.debug "Exec #{cmd}"
      stdn, stdo, stdr  = Open3.popen3(cmd)
      unless stdo.nil?
        # allow up to 90 secs. sometimes probing takes a while.
        tm = 90

        begin
          Timeout::timeout(tm) do
            loop do
              repl = stdo.gets
              unless repl.nil?
                reply.push = repl = repl.strip
                logger.debug { "GOT: #{repl}" }
                yield(repl) if block_given?
              end

              break if stdo.eof?
            end
          end
        rescue Timeout::Error
          logger.error { "Timeout! Unable to get response within #{tm} second(s)" }
        ensure
          stdo.close
          stdn.close
          stdr.close
        end
      else
        logger.error { "Open-pipe cmd returned nil. Something is wrong" }
      end

      reply
    end
  end
end
