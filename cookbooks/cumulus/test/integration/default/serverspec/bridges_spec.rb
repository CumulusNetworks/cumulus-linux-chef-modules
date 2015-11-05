require 'serverspec'

set :backend, :exec
set :path, '/bin:/usr/bin:/sbin/usr/sbin'

intf_dir = File.join('', 'etc', 'network', 'interfaces.d')

# Classic bridge driver
describe file("#{intf_dir}/br0") do
  it { should be_file }
  its(:content) { should match(/iface br0/) }
  its(:content) { should match(/bridge-ports swp31 glob swp32-33 swp34/) }
  its(:content) { should match(/bridge-stp yes/) }
end

describe file("#{intf_dir}/br1") do
  it { should be_file }
  its(:content) { should match(/iface br1/) }
  its(:content) { should match(/bridge-ports glob swp35-36/) }
  its(:content) { should match(/bridge-stp no/) }
  its(:content) { should match(/mtu 9000/) }
  its(:content) { should match(/mstpctl-treeprio 4096/) }
  its(:content) { should match(/address 10.0.0.1\/24/) }
  its(:content) { should match(/address 2001:db8:abcd::\/48/) }
end

# New bridge driver
describe file("#{intf_dir}/bridge2") do
  it { should be_file }
  its(:content) { should match(/iface bridge2/) }
  its(:content) { should match(/bridge-vlan-aware yes/) }
  its(:content) { should match(/bridge-ports glob swp37-38/) }
  its(:content) { should match(/bridge-stp yes/) }
end

describe file("#{intf_dir}/bridge3") do
  it { should be_file }
  its(:content) { should match(/iface bridge3/) }
  its(:content) { should match(/bridge-vlan-aware yes/) }
  its(:content) { should match(/bridge-ports glob swp39-40/) }
  its(:content) { should match(/bridge-stp no/) }
  its(:content) { should match(/mtu 9000/) }
  its(:content) { should match(/mstpctl-treeprio 4096/) }
  its(:content) { should match(/bridge-pvid 1/) }
  its(:content) { should match(/bridge-vids 1-4094/) }
  its(:content) { should match(/address 192.168.100.0\/16/) }
  its(:content) { should match(/address 2001:db8:1234::\/48/) }
  its(:content) { should match(/post-up ip route add 10.0.0.0\/8 via 192.168.200.2/) }
  its(:content) { should match(/post-up ip route add 172.16.0.0\/12 via 192.168.200.2/) }
  its(:content) { should match(/pre-down ip route del 10.0.0.0\/8 via 192.168.200.2/) }
  its(:content) { should match(/pre-down ip route del 172.16.0.0\/12 via 192.168.200.2/) }
end

describe file("#{intf_dir}/br4") do
  it { should be_file }
  its(:content) { should match(/iface br4/) }
  its(:content) { should match(/bridge-ports swp41/) }
  its(:content) { should match(/address 192.168.150.1/) }
end

describe file("#{intf_dir}/br5") do
  it { should be_file }
  its(:content) { should match(/iface br5/) }
  its(:content) { should match(/bridge-ports swp42/) }
  its(:content) { should match(/address 192.168.150.2/) }
  its(:content) { should match(/address 192.168.150.3/) }
  its(:content) { should match(/address 192.168.150.4/) }
  its(:content) { should match(/address 2001:db8:1234::e/) }
  its(:content) { should match(/address 2001:db8:1234::f/) }
end
