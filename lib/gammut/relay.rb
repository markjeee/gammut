module Gammut
  # How relay works:
  #
  # (1) incoming -- [POST] http://somehost.com/sms/incoming
  # (2) outgoing -- [POST] http://somehost.com/sms/outgoing
  # (3) mark sent -- [POST] http://somehost.com/sms/mark_sent
  #
  # This is a relay service that fetches incoming SMS from smsd db,
  # and relay it to a gammut_campout service via HTTP service. It
  # works both for incoming and outgoing messages.
  class Relay
    def initialize
    end

    def start
    end

    def stop
    end

    def status
    end
  end
end
