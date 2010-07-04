module Gammut
  module Sms
    # check at smsd.inbox, returns Gammut::SmsUtil::Message
    def self.find_new_messages(recipients = nil, limit = 100)
      Gammut::SmsUtil.messages(Gammut.database, recipients, limit, false)
    end

    def self.find_new_message_ids(recipients = nil, limit = 100)
      Gammut::SmsUtil.message_ids(Gammut.database, recipients, limit, false)
    end
  end
end
