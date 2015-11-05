#
# Cookbook Name:: cumulus-test
# Recipe:: bridges
#
# Copyright 2015, Cumulus Networks
#
# All rights reserved - Do Not Redistribute
#

# swp31-50

# Classic bridge driver with defaults
cumulus_bridge 'br0' do
  ports ['swp31', 'swp32-33', 'swp34']
end

# Classic bridge driver over-ride all defaults
cumulus_bridge 'br1' do
  ports ['swp35-36']
  ipv4 ['10.0.0.1/24', '192.168.1.0/16']
  ipv6 ['2001:db8:abcd::/48']
  alias_name 'classic bridge number 1'
  mtu 9000
  stp false
  mstpctl_treeprio 4096
  virtual_ip '192.168.100.1'
end

# New bridge driver with defaults
cumulus_bridge 'bridge2' do
  ports ['swp37-38']
  vlan_aware true 
end

# New bridge driver over-ride all defaults
cumulus_bridge 'bridge3' do
  ports ['swp39-40']
  vlan_aware true
  vids ['1-4094']
  pvid 1
  ipv4 ['10.0.100.1/24', '192.168.100.0/16']
  ipv6 ['2001:db8:1234::/48']
  alias_name 'new bridge number 3'
  mtu 9000
  stp false
  mstpctl_treeprio 4096
  virtual_mac 'aa:bb:cc:dd:ee:ff'
  post_up [
    "ip route add 10.0.0.0/8 via 192.168.200.2",
    "ip route add 172.16.0.0/12 via 192.168.200.2"
  ]
  pre_down [
    "ip route del 10.0.0.0/8 via 192.168.200.2",
    "ip route del 172.16.0.0/12 via 192.168.200.2"
  ]
end

# Single & multiple IPv4 & IPv6 addresses
cumulus_bridge 'br4' do
  ports ['swp41']
  ipv4 ['192.168.150.1']
end

cumulus_bridge 'br5' do
  ports ['swp42']
  ipv4 ['192.168.150.2','192.168.150.3','192.168.150.4']
  ipv6 ['2001:db8:1234::e','2001:db8:1234::f']
end
