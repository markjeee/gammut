module Gammut::Relay
  class WorkerPuppet < Palmade::PuppetMaster::EventdPuppet
    def initialize(options = { }, &block)
      super(options, &block)

      @proc_tag = 'worker'
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

      ret
    end

    def perform_work(w)
      transport = w.data[:transport]
      transport.do_work
    end

    def after_work(w, ret = nil)
      super(w, ret)

      w.data[:transport].shutdown!
    end
  end
end
