# Copyright (C) 2015  Cumulus Networks Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
require 'json'

# Top level namespace for Cumulus Networks
module Cumulus
  # General utility functions
  module Utils
    class << self
      ##
      # Take an array of ports and expand any ranges into individual items.
      #
      # = Example:
      #
      #   expand_port_list(['swp1','swp5-7', 'swp20'])
      #   => ["swp1", "swp5", "swp6", "swp7", "swp20"]
      #
      # = Parameters:
      # list::
      #   An array of ports, some of which may be a port range
      #
      # = Returns:
      # The expanded array of ports
      #
      def expand_port_list(list = [])
        out = []
        list.each do |port|
          match = port.match(/(\w+[a-z.])(\d+)?-?(\d+)?(\w+)?/)
          next unless match
          if match[3].nil?
            out << port
          else
            out.concat((match[2].to_i..match[3].to_i).to_a.map { |p| "#{match[1]}#{p}#{match[4]}" })
          end
        end
        out
      end

      ##
      # Take an array of ports and prefix any ranges with the 'glob' keyword
      # for ifupdown2.
      #
      # = Example:
      #
      #   prefix_glob_port_list(['swp1','swp5-7', 'swp20'])
      #   => ["swp1", "glob swp5-7", "swp20"]
      #
      # = Parameters:
      # list::
      #   An array of ports, some of which may be a port range
      #
      # = Returns:
      # The array of ports with any ranges prefixed with the 'glob' keyword
      #
      def prefix_glob_port_list(list = [])
        out = []
        list.each do |port|
          match = port.match(/^(.+)-(.+)$/)
          if match
            out << "glob #{port}"
          else
            out << port
          end
        end
        out
      end

      ##
      # Generate a single unified hash of the ports and their speeds, and return
      # a hash sorted by port number.
      #
      # = Example:
      #
      #   gen_port_hash(['swp1'], ['swp5','swp6'], ['swp10'], ['swp12'])
      #   => [[1, "40G"], [5, "10G"], [6, "10G"], [10, "4x10G"], [12, "40G/4"]]
      #
      # = Parameters:
      # speed_40g::
      #   An array of 40G ports
      # speed_10g::
      #   An array of 10G ports
      # speed_4_by_10g
      #   An array of 4x10G ports
      # speed_40g_div_4
      #   An array of 40G/4 ports
      #
      # = Returns:
      # A sorted hash of the ports and their configured speeds
      #
      def gen_port_hash(speed_40g = [], speed_10g = [], speed_4_by_10g = [], speed_40g_div_4 = [])
        port_hash = {}
        speed_40g.each do |port|
          match = port.match(/(\d+)/)
          if match
            port_num = match[1]
            port_hash[port_num.to_i] = '40G'
          else
            Chef::Log.info("Invalid port #{port}")
          end
        end

        speed_10g.each do |port|
          match = port.match(/(\d+)/)
          if match
            port_num = match[1]
            port_hash[port_num.to_i] = '10G'
          else
            Chef::Log.info("Invalid port #{port}")
          end
        end

        speed_4_by_10g.each do |port|
          match = port.match(/(\d+)/)
          if match
            port_num = match[1]
            port_hash[port_num.to_i] = '4x10G'
          else
            Chef::Log.info("Invalid port #{port}")
          end
        end

        speed_40g_div_4.each do |port|
          match = port.match(/(\d+)/)
          if match
            port_num = match[1]
            port_hash[port_num.to_i] = '40G/4'
          else
            Chef::Log.info("Invalid port #{port}")
          end
        end

        # Return the full hash sorted by the key (I.e. numeric order)
        port_hash.sort
      end

      ##
      # Use ifquery to generate a JSON representation of an interface and
      # return the hash.
      #
      # = Example:
      #
      #   if_to_hash('eth0')
      #   => [{"auto"=>true, "name"=>"eth0", "config"=>{...}, ...}]
      #
      # = Parameters:
      # name::
      #   Interface to retrieve
      #
      def if_to_hash(name)
        begin
          json = ''
          IO.popen("ifquery #{name} -o json") do |ifquery|
            json = ifquery.read
          end
          return JSON.load(json)
        rescue StandardError => ex
          Chef::Log.fatal("failed to run ifquery for interface #{name}:  #{ex}")
        end
      end

      ##
      # Use ifquery to generate a configuration from a hash and return the
      # configuration.
      #
      # = Example:
      #
      #   h = [{'name' => 'eth0', 'auto' => true, config => {...}, ...}]
      #   hash_to_if('eth0', h)
      #   => 'auto eth0\niface eth0\n...'
      #
      # = Parameters::
      # name::
      #   Interface name
      # hash::
      #   Configuration for the interface.
      #
      # = Note::
      # Although the configuration is nominally a hash, ifquery expects each
      # object to be enclosed within an array; ifquery can process multiple
      # interfaces at once, where each interfaces is an element within the
      # array, so a single interface is a single element inside an array.
      # However, "array_to_if" isn't very descriptive and we only deal with
      # a single interface at a time. Just be sure to always wrap the hash with
      # an array.
      #
      def hash_to_if(name, hash)
        begin
          intf = ''
          IO.popen("ifquery -i - -t json #{name}", 'r+') do |ifquery|
            ifquery.write(hash.to_json)
            ifquery.close_write

            intf = ifquery.read
            ifquery.close
          end
          Chef::Log.debug("ifquery produced the following:\n#{intf}")
          return intf
        rescue StandardError => ex
          Chef::Log.fatal("failed to run ifquery -i for interface #{name}:  #{ex}\nInput was #{hash.to_json}")
        end
      end

      ##
      # Convert a boolean value to "yes" or "no" (rather than to_s which
      # converts to "True" and "False"
      #
      # = Example
      #
      #   bool_to_yn(true)
      #   => 'yes'
      #
      # = Parameters::
      # bool::
      #   Boolean value to convert from
      #
      def bool_to_yn(bool)
        bool ? 'yes' : 'no'
      end

      ##
      # Convert an integer to string (works for integers and arrays)
      #
      # = Example
      #
      #   convert_int_to_string(401)
      #   => '401'
      #
      #   convert_int_to_string([401,402])
      #   => ['401','402']
      #
      # = Parameters::
      # object::
      #   Integer or Array value to convert from
      #
      def convert_int_to_string(object)
        if object.is_a?(Integer)
          object.to_s
        elsif object.is_a?(Array)
          object.map! {|obj| convert_int_to_string(obj)}
        else
          object
        end
      end
    end
  end
end
