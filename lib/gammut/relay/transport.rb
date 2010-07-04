module Gammut::Relay
  # The transport has 3 major functions:
  #
  # (1) Check the smsd.inbox for new messages
  # (2) Check the outgoing web service for messages to be sent
  # (3) Query smsd.sent_items for sent items and update the web
  # service
  class Transport
    def initialize(rcache)
      @rcache = rcache
    end

    def shutdown!

    end
  end
end
