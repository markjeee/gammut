module Gammut
  module SmsUtil
    NETWORKS = %w{ globe smart sun }

    GLOBE_NETWORK = %w{ 905 906 915 916 917 926 927 935 936 937 }
    SMART_NETWORK = %w{ 907 908 909 910 912 918 919 920 921 928 929 930 938 939 }
    SUN_NETWORK = %w{ 922 923 932 }

    DT_DB_FORMAT = "%Y-%m-%d %H:%M:%S".freeze

    class UDH < Struct.new(:multipart,
                           :multipart_id,
                           :multipart_count,
                           :multipart_no)
    end

    class Message
      attr_accessor :id
      attr_accessor :sender_number
      attr_accessor :orig_message
      attr_accessor :recipient
      attr_accessor :udh_text

      attr_reader :udh

      # these two are only set when this is part of a multipart
      # message, and this is part no. 1
      attr_reader :multipart_ids
      attr_reader :multipart_others

      def initialize(conn, hash_data)
        @conn = conn
        @complete = false

        parse!(hash_data)
      end

      def parse!(hash_data)
        @hash_data = hash_data

        @id = hash_data[:ID]
        @udh_text = @hash_data[:UDH].strip

        # let's parse udh, if it's specified
        unless @udh_text.nil? || @udh_text.empty?
          parse_udh!
        end

        @sender_number = @hash_data[:SenderNumber]

        if @hash_data.include?(:TextDecoded)
          @orig_message = @hash_data[:TextDecoded]
          @recipient = @hash_data[:RecipientID].strip

          if multipart?
            @message = @hash_data[:TextDecoded].dup.freeze
          else
            @message = @hash_data[:TextDecoded].lstrip.freeze
          end

          @complete = true
        end

        self
      end

      def complete?
        @complete
      end

      def message
        if complete?
          if multipart? && multipart_head? && multipart_complete?
            # let's concatenate all the message
            if defined?(@multipart_message)
              @multipart_message
            else
              @multipart_message = ([ @message ].
                                    concat((2..udh.multipart_count).
                                           collect { |i| multipart_others[i].message })).join("").lstrip.freeze
            end
          else
            @message
          end
        else
          raise "Incomplete message"
        end
      end

      def processed!
        if multipart? && multipart_head? && multipart_complete?
          @conn[:inbox].where(:ID => multipart_ids).update(:Processed => 'true')
        else
          @conn[:inbox].where(:ID => id).update(:Processed => 'true')
        end

        @hash_data[:Processed] = 'true'
      end

      def processed?
        @hash_data[:Processed] == 'true'
      end

      def multipart?
        unless udh.nil?
          udh.multipart == true
        else
          false
        end
      end

      def multipart_head?
        udh.multipart_no == 1
      end

      def multipart_complete?
        # meaning, we're complete, if all the parts are found
        udh.multipart_count == multipart_ids.size &&
          udh.multipart_count == (@multipart_others.keys.size + 1) # +1 as me, the header
      end

      def multipart_add_others(parts)
        parts.each do |pm|
          mno = pm.udh.multipart_no
          unless @multipart_others.include?(mno)
            @multipart_ids.add(pm.id)
            @multipart_others[mno] = pm
          end
        end
      end

      protected

      def parse_udh!
        # 05 = 5 bytes follow
        # 00 = indicator for concatenated message
        # 03 = three bytes follow
        # 5F = message identification. Each part has the same value here
        # 02 = the concatenated message has 2 parts
        # 01 = this is part 1
        # reference: http://smstools.meinemullemaus.de/udh.html

        bytes = udh_text.gsub(/../) { |p| [ p ].pack("H2") }

        nbytes = bytes[0] # probably, not useful, for concatenated sms
        case bytes[1]
        when 0 # indicates a concatenated message
          # bytes[2] indicates how many bytes after this, ignore

          @udh = UDH.new
          @udh.multipart = true
          @udh.multipart_id = bytes[3]
          @udh.multipart_count = bytes[4]
          @udh.multipart_no = bytes[5]

          if multipart_head?
            @multipart_ids = Set.new(id)
            @multipart_others = { }
          end
        else
          # do nothing
          @udh = nil
        end

        udh
      end
    end

    def self.parse_multiparts(parsed_msgs)
      # let's parse for multiparts
      multiparts = { }

      # remove multi-parts first, and group them by id
      parsed_msgs.delete_if do |pm|
        if pm.multipart?
          mid = "#{pm.sender_number}-#{pm.udh.multipart_id}"
          multiparts[mid] = [ ] unless multiparts.include?(mid)
          multiparts[mid] << pm

          true
        else
          false
        end
      end

      unless multiparts.empty? # we found some multipart head messages
        multiparts.each do |mid, parts|
          head = nil

          # find the head (multipart_no == 1)
          parts.delete_if do |pm|
            if pm.multipart_head?
              head = pm; true
            else
              false
            end
          end

          unless head.nil? # only process if a head is found, and if it's complete
            head.multipart_add_others(parts)

            if head.multipart_complete?
              parsed_msgs << head
            end
          end
        end
      end

      parsed_msgs
    end

    def self.message_ids(conn, recipients, limit = 100, processed = false, parse_multipart = true)
      messages(conn, recipients, limit, processed, parse_multipart, false)
    end

    def self.messages(conn, recipients = nil, limit = 100, processed = false, parse_multipart = true, complete = true)
      # if processing multi-parts, only get ID, UDH, SenderNumber, Processed
      if complete
        ds = conn[:inbox].select_all
      else
        ds = conn[:inbox].select(:ID, :UDH, :SenderNumber, :Processed)
      end

      if processed
        ds = ds.where(:Processed => 'true')
      else
        ds = ds.where(:Processed => 'false')
      end

      unless recipients.nil?
        recipients = [ recipients ] unless recipients.is_a?(Array)
        ds = ds.where(:RecipientID => recipients)
      end

      ds = ds.limit(1000)

      parsed_msgs = ds.collect { |msg| SmsUtil::Message.new(conn, msg) }
      parsed_msgs = parse_multiparts(parsed_msgs) if parse_multipart

      # the returned limit is just based on the array slice
      parsed_msgs[0, limit]
    end

    def self.ssend(conn, number, msg, creator_tag = nil, sender_id = nil)
      # InsertIntoDB !!
      # DestinationNumber !!
      # Coding = Default_No_Compression
      # Class = 0
      # TextDecoded = <sms message> !!
      # MultiPart = false
      # SenderID = globe | sun | smart (network info)
      # CreatorID = globe !!

      network = which_network(number)

      creator_id = "SmsUtil: #{$$}"
      unless creator_tag.nil?
        creator_id += ",#{creator_tag}"
      end

      values = { }

      # InsertIntoDB
      values[:InsertIntoDB] = Time.now

      # DestinationNumber
      values[:DestinationNumber] = number

      # TextDecoded
      if msg.length > 156
        msg = "#{msg[0,156]}..."
      else
        msg = "#{msg}"
      end

      # gammu seems to hang if there is a message with lots if this '~'
      msg.gsub!(/\~{2,}/, '~')

      values[:TextDecoded] = msg

      # SenderID
      if !sender_id.nil?
        values[:SenderID] = sender_id
      elsif !network.nil?
        values[:SenderID] = network
      end

      values[:CreatorID] = creator_id

      conn[:outbox].insert(values)
    end

    def self.which_network(number)
      # number is of this format
      # +63<area_code><number>
      # area_code: 3 numbers
      # phone: 7 numbers

      acode = nil
      if number.length == 10
        acode = number[0,3]
      elsif number =~ /\A\+?63(\d{3})\d{7}\Z/
        acode = $~[1]
      end

      unless acode.nil?
        if GLOBE_NETWORK.include?(acode)
          "globe"
        elsif SMART_NETWORK.include?(acode)
          "smart"
        elsif SUN_NETWORK.include?(acode)
          "sun"
        else
          nil
        end
      else
        nil
      end
    end
  end
end
