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
  module Relay
    autoload :WorkerPuppet, File.join(File.dirname(__FILE__), 'relay/worker_puppet')
    autoload :RelayPuppet, File.join(File.dirname(__FILE__), 'relay/relay_puppet')
    autoload :Transport, File.join(File.dirname(__FILE__), 'relay/relay_puppet')
  end
end
