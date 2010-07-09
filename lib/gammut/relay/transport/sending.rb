module Gammut::Relay
  class Transport
    module Sending
      def self.included(t)
        t.add_method(:relay_send, :perform_relay_send)
      end

      def relay_send(msg)
        logger.debug { "Marking for send: #{msg.id}" }
        msg.working!

        push_work(:relay_send, msg.id)
      end

      def perform_relay_send(msg_id)
        logger.debug { "Got msg for sending: #{msg_id}" }
      end
    end
  end
end
