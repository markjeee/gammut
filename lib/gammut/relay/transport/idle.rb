module Gammut::Relay
  class Transport
    module Idle
      def self.included(t)
        t.add_method(:idle, :perform_idle)
      end

      def idle
        push_work(:idle)
      end

      def perform_idle
        logger.debug "Performing idle tasks"
      end
    end
  end
end
