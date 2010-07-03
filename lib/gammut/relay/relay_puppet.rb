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
      db = Sequel.connect(db_config)
      master_logger.debug { "Gammut db config: #{db.inspect}" }

      w.data[:db] = db
    end

    def perform_work(w)

    end

    def after_work(w, ret = nil)
      master_logger.debug { "Closing db connection" }
      w.data[:db].disconnect
    end
  end
end
