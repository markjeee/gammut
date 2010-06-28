require 'open3'

module Gammut
  module Utils
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
                reply.push(repl = repl.strip)
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
