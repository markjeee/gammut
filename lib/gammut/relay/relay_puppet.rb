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
      super(w)

      Gammut.init(ROOT_PATH, Gammut.gammut_logger)

      w.data[:db] = db = Sequel.connect(Gammut.database_config)
      master_logger.debug { "Gammut db config: #{db.inspect}" }

      ret
    end

    def perform_work(w)

    end

    def after_work(w, ret = nil)
      master_logger.debug { "Closing db connection" }
      w.data[:db].disconnect
      w.data.delete(:db)
    end
  end
end
