module Gammut::Relay
  class WorkerPuppet < Palmade::PuppetMaster::EventdPuppet
    def initialize(options = { }, &block)
      super(options, &block)
      @proc_tag = 'worker'
    end

    def after_fork(w)
      super(w)
      Gammut.init(ROOT_PATH, Gammut.gammut_logger)
    end

    def perform_work(w)

    end
  end
end
