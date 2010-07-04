module Gammut
  # How relay works:
  #
  # (1) incoming -- [POST] http://somehost.com/sms/incoming
  # (2) outgoing -- [POST] http://somehost.com/sms/outgoing
  # (3) mark sent -- [POST] http://somehost.com/sms/mark_sent
  #
  # This is a relay service that fetches incoming SMS from smsd db,
  # and relay it to a gammut_campout service via HTTP service. It
  # works both for incoming and outgoing messages.
  module Relay
    autoload :WorkerPuppet, File.join(File.dirname(__FILE__), 'relay/worker_puppet')
    autoload :RelayPuppet, File.join(File.dirname(__FILE__), 'relay/relay_puppet')
    autoload :Transport, File.join(File.dirname(__FILE__), 'relay/transport')
    autoload :Message, File.join(File.dirname(__FILE__), 'relay/message')

    def self.relay_logger(root_path = nil)
      l = Logger.new(File.join(root_path || ROOT_PATH, GAMMUT_RELAY_LOG))
      l.level = GAMMUT_RELAY_LOG_LEVEL
      l
    end

    def self.init(root_path, logger)
      Gammut.init(root_path, logger)

      @recipients = Set.new
      @services = { }

      svcs = Gammut.services
      unless svcs.nil? || svcs.empty?
        svcs.each do |s|
          if s.relay?
            @services[s.skey] = s
            @recipients.add(s.skey)
          end
        end
      end
    end

    def self.root_path; Gammut.root_path; end
    def self.logger; Gammut.logger; end
    def self.database; Gammut.database; end
    def self.services; @services; end
    def self.recipients; @recipients; end

    # check at smsd.inbox, returns Gammut::SmsUtil::Message
    def self.find_new_messages(recipients)
      # TODO
    end
  end
end
