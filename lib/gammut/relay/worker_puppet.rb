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

    def after_work(w, ret = nil)
      super(w)

      Gammut.init(ROOT_PATH, Gammut.gammut_logger)

      ret
    end

    def perform_work(w)

    end
  end
end
