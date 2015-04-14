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

def whyrun_supported?
  true
end

use_inline_resources

action :create do
  name = new_resource.name
  addr_method = new_resource.addr_method
  slaves = Cumulus::Utils.prefix_glob_port_list(new_resource.slaves)
  alias_name = new_resource.alias_name
  mtu = new_resource.mtu
  clag_id = new_resource.clag_id
  virtual_mac = new_resource.virtual_mac
  virtual_ip = new_resource.virtual_ip
  vids = new_resource.vids
  pvid = new_resource.pvid
  mstpctl_portnetwork = new_resource.mstpctl_portnetwork
  mstpctl_bpduguard = new_resource.mstpctl_bpduguard
  location = new_resource.location

  ipv4 = new_resource.ipv4
  ipv6 = new_resource.ipv6
  address = ipv4 + ipv6

  config = { 'bond-slaves' => slaves,
             'bond-miimon' => new_resource.miimon,
             'bond-min-links' => new_resource.min_links,
             'bond-mode' => new_resource.mode,
             'bond-xmit-hash-policy' => new_resource.xmit_hash_policy,
             'bond-lacp-rate' => new_resource.lacp_rate }

  # Insert optional parameters
  config['address'] = address unless address.nil?
  config['alias'] = "\"#{alias_name}\"" unless alias_name.nil?
  config['mtu'] = mtu unless mtu.nil?
  config['clag-id'] = clag_id unless clag_id.nil?
  config['bridge-vids'] = vids unless vids.nil?
  config['bridge-pvid'] = pvid unless pvid.nil?
  config['address-virtual'] = virtual_mac unless virtual_mac.nil?
  config['address-virtual'] = virtual_ip unless virtual_ip.nil?
  config['mstpctl-portnetwork'] = Cumulus::Utils.bool_to_yn(mstpctl_portnetwork) unless mstpctl_portnetwork.nil?
  config['mstpctl-bpduguard'] = Cumulus::Utils.bool_to_yn(mstpctl_bpduguard) unless mstpctl_bpduguard.nil?

  # Family is always 'inet' if a method is set
  addr_family = addr_method.nil? ? nil : 'inet'

  new = [{ 'auto' => true,
           'name' => name,
           'config' => config,
           'addr_method' => addr_method,
           'addr_family' => addr_family }]

  current = Cumulus::Utils.if_to_hash(name)

  Chef::Log.debug("current config for bond #{name} is #{current.to_json}")
  Chef::Log.debug("desired config for bond #{name} is #{new.to_json}")

  if current.nil? || current != new
    Chef::Log.debug("updating config for bond #{name}")

    intf = Cumulus::Utils.hash_to_if(name, new)

    file ::File.join(location, name) do
      owner 'root'
      group 'root'
      content intf
    end

    new_resource.updated_by_last_action(true)
  end
end
