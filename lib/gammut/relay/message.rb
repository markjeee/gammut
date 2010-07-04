module Gammut::Relay
  # corresponds to a record in inbox_relay table
  class Message
    attr_reader :recipient_id

    # check at smsd.inbox_relay
    def self.reset_all_messages(recipients)
      # TODO
    end

    # check at smsd.inbox_relay, returns Gammut::Relay::Message
    def self.reset_overdue_messages(recipients)
      # TODO
    end

    # check at smsd.inbox_relay, accepts Gammut::SmsUtil::Message
    def self.enqueue_message(msg)
      # TODO
    end

    # check at smsd.inbox_relay, returns Gammut::Relay::Message
    def self.find_pending_messages(recipients)
      # TODO
    end

    def initialize(conn)
      @conn = conn
    end

    # return a string representation of this message
    def serialize
    end

    # mark sent_at and unmark worked_at
    def done!
    end

    # marked as being worked_at
    def working!
    end

    # increment try_count, and unmark worked_at
    def requeue!
    end
  end
end
