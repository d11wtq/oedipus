# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "socket"
require "net/protocol"

module Oedipus
  module Mysql
    # Limited subset of MySQL protocol for communication with SphinxQL.
    #
    # This needs to exist since other ruby MySQL clients do not provide the relevant features.
    class Client
      # Connect to the SphinxQL server.
      #
      # @param [Hash]
      #   a Hash containing :host and :port
      def initialize(options)
        @sock = TCPSocket.new(options[:host], options[:port])
        @seq  = 0
        perform_handshake
      end

      def execute(sql)
        p send_packet(query_packet(sql))
      end

      private

      def perform_handshake
        auth_pkt = clnt_authentication_packet(serv_initialization_packet)
        raise "Some sort of error" unless send_packet(auth_pkt)[:type] == :ok
      end

      def incr_seq(seq)
        raise ProtocolError, "Invalid packet sequence value #{seq} != #{@seq}" unless seq == @seq
        @seq = (seq + 1) % 256
      end

      def recv_packet
        a, b, seq = @sock.read(4).unpack("CvC")
        incr_seq(seq)
        @sock.read(a | (b << 8))
      end

      def send_packet(pkt)
        while chunk = pkt.read(2**24 - 1)
          @sock.write([chunk.length % 256, chunk.length / 256, @seq, chunk].pack("CvCZ*"))
          incr_seq(@seq)
        end

        serv_result_packet
      end

      def serv_result_packet
        pkt = recv_packet
        case pkt[0]
        when "\x00" then ok_packet(pkt)
        else raise ProtocolError, "Unknown packet type #{pkt[0]}"
        end
      end

      def scan_lcb(str)
        case v = str.slice!(0)
        when "\xFB" then nil
        when "\xFC" then str.slice!(0, 2).unpack("v").first
        when "\xFD"
          a, b = str.slice!(0, 3).unpack("Cv")
          a | (b << 8)
        when "\xFE"
          a, b = str.slice!(0, 8).unpack("VV")
          a | (b << 32)
        else v.ord
        end
      end

      def ok_packet(str)
        Hash[
          [
            :field_count,
            :affected_rows,
            :insert_id,
            :serv_stat,
            :warning_count,
            :message
          ].zip([scan_lcb(str), scan_lcb(str), scan_lcb(str)] + str.unpack("vva*"))
        ].tap { |pkt| pkt[:type] = :ok }
      end

      def serv_initialization_packet
        Hash[
          [
            :prot_ver,
            :serv_ver,
            :thread_id,
            :scramble_buf_a,
            :filler_a,
            :serv_cap_a,
            :serv_enc,
            :serv_stat,
            :serv_cap_b,
            :scramble_len,
            :filler_b,
            :scramble_buf_b
          ].zip(recv_packet.unpack("CZ*Va8CvCvvCa10Z*"))
        ].tap do |pkt|
          raise ProtocolError, "Unsupported MySQL protocol version #{pkt[:prot_ver]}" unless pkt[:prot_ver] == 0x0A
        end
      end

      def clnt_authentication_packet(init_pkt)
        StringIO.new [
          197120,  # clnt_cap (prot 4.1, multi-stmt, multi-rs)
          1024**3, # max pkt size
          0,       # charset not used
          '',      # filler 23 bytes
          '',      # username not used
          '',      # scramble buf (no password)
          ''       # dbname not used
        ].pack("VVCa23Z*A*Z*")
      end

      def query_packet(sql)
        StringIO.new [
          0x03,  # COM_QUERY type
          sql
        ].pack("Ca*")
      end
    end
  end
end
