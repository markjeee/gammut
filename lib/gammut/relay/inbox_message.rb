module Gammut::Relay
  # corresponds to a record in inbox_relay table
  class InboxMessage
    WORKED_AT_LIMIT = 3 * 60
    RT_AT_INTERVAL = 3 * 60

    def self.ir; Gammut.database[:inbox_relay]; end
    def ir; self.class.ir; end

    # check at smsd.inbox_relay
    def self.reset_all_messages(recipients = nil)
      ds = ir.select(:ID).where("worked_at IS NOT NULL")
      unless recipients.nil?
        ds = ds.where(:recipient_id => recipients.to_a)
      end
      ds.update(:worked_at => nil)
    end

    # check at smsd.inbox_relay, returns Gammut::Relay::Message
    def self.reset_overdue_messages(recipients = nil, worked_at_limit = WORKED_AT_LIMIT, nw = Time.now)
      wal = nw - worked_at_limit
      ds = ir.select(:ID).where("worked_at IS NOT NULL AND worked_at < ?", wal)
      unless recipients.nil?
        ds = ds.where(:recipient_id => recipients.to_a)
      end

      ims = [ ]
      ds.all.collect do |m|
        im = self.new(m)
        im.requeue!
        ims.push(im)
      end
      ims
    end

    # check at smsd.inbox_relay, accepts Gammut::SmsUtil::Message
    def self.enqueue_message(msg)
      raise "Incomplete SMS message" unless msg.complete?

      im = { }
      im[:ID] = msg.id
      im[:sender_number] = msg.sender_number

      im[:message] = msg.message
      im[:received_at] = msg.received_at
      im[:recipient_id] = msg.recipient
      im[:network] = msg.network

      ir.insert(im)
    end

    # check at smsd.inbox_relay, returns Gammut::Relay::Message
    def self.find_pending_messages(recipients = nil, limit = 10, nw = Time.now)
      ds = ir.select_all.where(:sent_at => nil,
                               :worked_at => nil)
      ds = ds.where("rt_at IS NULL OR rt_at < ?", nw)
      unless recipients.nil?
        ds = ds.where(:recipient_id => recipients.to_a)
      end
      ds = ds.order('id ASC').limit(limit)

      ims = [ ]
      ds.each do |im|
        ims.push(self.new(im))
      end
      ims
    end

    attr_reader :id

    def initialize(attributes = { })
      @attributes = attributes
      @id = attributes[:ID]
    end

    # return a string representation of this message
    def serialize
      if defined?(::Yajl)
        Yajl::Encoder.encode(@attributes)
      else
        nil
      end
    end

    # marked as being worked_at
    def working!(nw = Time.now)
      ds = ir.where(:ID => @id)
      ds.update(:worked_at => nw)
    end

    # mark sent_at and unmark worked_at
    def done!(nw = Time.now)
      ds = ir.where(:ID => @id)
      ds.update(:worked_at => nil, :sent_at => nw)
    end

    # increment try_count, and unmark worked_at
    def requeue!(nw = Time.now)
      ds = ir.where(:ID => @id)

      tc = @attributes[:try_count].to_i
      rt_at = Time.now + ((tc + 1) * RT_AT_INTERVAL)
      ds.update(:worked_at => nil, :try_count => tc + 1, :rt_at => rt_at)
    end
  end
end
