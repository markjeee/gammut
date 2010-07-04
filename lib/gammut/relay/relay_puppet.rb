module Gammut::Relay
  class RelayPuppet < Palmade::PuppetMaster::EventdPuppet
    def initialize(options = { }, &block)
      super(options, &block)

      @proc_tag = 'relay'
      if @options.include?(:cache_key_prefix)
        @cache_key_prefix = @options[:cache_key_prefix]
      else
        @cache_key_prefix = 'gammut_relay'
      end
    end

    def before_work(w, ret = nil)
      super(w, ret)
      master = w.master

      Gammut::Relay.init(ROOT_PATH, l = Gammut::Relay.relay_logger)

      w.data[:recipients] = recipients = Gammut::Relay.recipients
      rcache = master.services[:redis].client
      w.data[:transport] = Gammut::Relay::Transport.new(rcache)

      l.debug { "Connected to redis: #{rcache.inspect}" }
      l.debug { "Working with recipients: #{recipients.inspect}" }

      # (1) re-set worked_at fields
      Gammut::Relay::Message.reset_all_messages(recipients)

      ret
    end

    def perform_work(w)
      recipients = w.data[:recipients]
      transport = w.data[:transport]

      # (1) check for overdue items
      Gammut::Relay::Message.reset_overdue_messages(recipients)

      # (2) check smsd.inbox for new messages
      Gammut::Relay.find_new_messages(recipients) do |sms|
        Gammut::Relay::Message.enqueue_message(sms)
        sms.processed!
      end

      # (3) Find pending messages for working
      msgs = Gammut::Relay::Message.find_pending_messages(recipients)
      unless msgs.nil? || msgs.empty?
        transport.enqueue_for_sending(msgs)
      else
        # else, no messages for sending
      end
    end

    def after_work(w, ret = nil)
      super(w, ret)

      w.data[:transport].shutdown!
    end
  end
end
