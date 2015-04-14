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
def whyrun_supported?
  true
end

use_inline_resources

action :create do
  name = new_resource.name
  addr_method = new_resource.addr_method
  ports = Cumulus::Utils.prefix_glob_port_list(new_resource.ports)
  mtu = new_resource.mtu
  mstpctl_treeprio = new_resource.mstpctl_treeprio
  alias_name = new_resource.alias_name
  virtual_ip = new_resource.virtual_ip
  virtual_mac = new_resource.virtual_mac
  location = new_resource.location

  ipv4 = new_resource.ipv4
  ipv6 = new_resource.ipv6
  address = ipv4 + ipv6

  config = { 'bridge-ports' => ports,
             'bridge-stp' => Cumulus::Utils.bool_to_yn(new_resource.stp) }

  # Insert optional parameters
  config['address'] = address unless address.nil?
  config['mtu'] = mtu unless mtu.nil?
  config['mstpctl-treeprio'] = mstpctl_treeprio unless mstpctl_treeprio.nil?
  config['alias'] = "\"#{alias_name}\"" unless alias_name.nil?
  config['address-virtual'] = virtual_ip unless virtual_ip.nil?
  config['address-virtual'] = virtual_mac unless virtual_mac.nil?

  if new_resource.vlan_aware
    config['bridge-vlan-aware'] = 'yes'

    # vids & pvid are valid
    vids = new_resource.vids
    pvid = new_resource.pvid

    config['bridge-vids'] = vids unless vids.nil?
    config['bridge-pvid'] = pvid unless pvid.nil?
  end

  # Family is always 'inet' if a method is set
  addr_family = addr_method.nil? ? nil : 'inet'

  new = [{ 'auto' => true,
           'name' => name,
           'config' => config,
           'addr_method' => addr_method,
           'addr_family' => addr_family }]

  current = Cumulus::Utils.if_to_hash(name)

  Chef::Log.debug("current config for bridge #{name} is #{current.to_json}")
  Chef::Log.debug("desired config for bridge #{name} is #{new.to_json}")

  if current.nil? || current != new
    Chef::Log.debug("updating config for bridge #{name}")

    intf = Cumulus::Utils.hash_to_if(name, new)

    file ::File.join(location, name) do
      owner 'root'
      group 'root'
      content intf
    end

    new_resource.updated_by_last_action(true)
  end
end
