module Gammut::Relay
  # The transport has 3 major functions:
  #
  # (1) Check the smsd.inbox for new messages
  # (2) Check the outgoing web service for messages to be sent
  # (3) Query smsd.sent_items for sent items and update the web
  # service
  #
  # A transport object/instance is specific to a gammut service. There
  # will be N transports tagged in the puppets for N service.
  class Transport
    def initialize(svc)
      @svc = svc
    end
  end
end
