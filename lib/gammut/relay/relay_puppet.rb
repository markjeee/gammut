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
      rcache = master.services[:redis].client

      Gammut::Relay.init(ROOT_PATH, l = Gammut::Relay.relay_logger)
      recipients = Gammut::Relay.recipients
      w.data[:transport] = Gammut::Relay::Transport.new(rcache)

      l.debug { "Connected to redis: #{rcache.inspect}" }
      unless recipients.empty?
        l.debug { "Working with recipients: #{recipients.inspect}" }
      else
        l.warn { "Working with an empty recipients (meaning? nothing to do)" }
      end

      # (1) re-set worked_at fields
      Gammut::Relay::InboxMessage.reset_all_messages(recipients)

      ret
    end

    def perform_work(w)
      db = Gammut.database
      l = Gammut.logger
      recipients = Gammut::Relay.recipients
      transport = w.data[:transport]

      processed = 0
      unless recipients.empty?
        # (1) check for overdue items
        db.transaction do
          overdue_ims = Gammut::Relay::InboxMessage.reset_overdue_messages(recipients)
          unless overdue_ims.empty?
            l.warn { "Found #{overdue_ims.size} overdue messages" }
          end
        end

        # (2) check smsd.inbox for new messages
        db.transaction do
          smses = Gammut::Sms.find_new_messages(recipients.to_a)
          unless smses.nil? || smses.empty?
            smses.each do |sms|
              Gammut::Relay::InboxMessage.enqueue_message(sms)
              sms.processed!
            end
            processed += smses.count
          end
        end

        db.transaction do
          # (3) Find pending messages for working
          msgs = Gammut::Relay::InboxMessage.find_pending_messages(recipients)
          unless msgs.nil? || msgs.empty?
            msgs.each { |m| transport.relay_send(m) }
            processed += msgs.count
          end
        end

        # (4) Check sent smses, and mark relay

        # (5) Enqueue to retrieve pending messages from relay endpoint
      end

      transport.idle if processed == 0
    end

    def after_work(w, ret = nil)
      super(w, ret)

      w.data[:transport].shutdown!
    end
  end
end
