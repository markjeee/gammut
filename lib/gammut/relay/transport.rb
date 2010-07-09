module Gammut::Relay
  # The transport has 3 major functions:
  #
  # (1) Check the smsd.inbox for new messages
  # (2) Check the outgoing web service for messages to be sent
  # (3) Query smsd.sent_items for sent items and update the web
  # service
  class Transport
    @@known_methods = { }
    def self.known_methods; @@known_methods; end
    def known_methods; self.class.known_methods; end

    def self.add_method(meth, work_meth)
      known_methods[meth] = work_meth
    end

    attr_reader :logger

    def initialize(rcache, tubename = 'relay_transport')
      @logger = Gammut.logger
      @rcache = rcache
      @tubename = tubename
    end

    def shutdown!
    end

    def do_work
      job = pop_work
      unless job.nil?
        action, *args = job

        Gammut.capture_and_log_errors(true) do
          action = action.to_sym
          if known_methods.include?(action)
            send(known_methods[action], *args)
          else
            logger.warn { "Received unknown action: #{action} with args #{args.inspect}" }
          end
        end
      end
    end

    def push_work(*args)
      @rcache.rpush(@tubename, Yajl::Encoder.encode(args))
    end

    def pop_work
      payload = @rcache.rpop(@tubename)
      unless payload.nil?
        Yajl::Parser.parse(payload)
      else
        nil
      end
    end

    require File.join(File.dirname(__FILE__), 'transport/idle')
    require File.join(File.dirname(__FILE__), 'transport/sending')
    require File.join(File.dirname(__FILE__), 'transport/receiving')

    include Gammut::Relay::Transport::Idle
    include Gammut::Relay::Transport::Sending
    include Gammut::Relay::Transport::Receiving
  end
end
