module Gammut::Relay
  class RelayPuppet < Palmade::PuppetMaster::EventdPuppet
    def initialize(options = { }, &block)
      super(options, &block)
      @proc_tag = 'relay'
    end

    def after_fork(w)
      super(w)
      Gammut.init(ROOT_PATH, Gammut.gammut_logger)

      db_config = Gammut.database_config
      master_logger.debug { "Gammut db config: #{db_config.inspect}" }
      db = Sequel.connect(db_config)
    end

    def perform_work(w)

    end
  end
end
