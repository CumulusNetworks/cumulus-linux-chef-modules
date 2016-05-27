require 'serverspec'

set :backend, :exec
set :path, '/bin:/usr/bin:/sbin/usr/sbin'

intf_dir = File.join('', 'etc', 'network', 'interfaces.d')

# The recipe should have created the .d directory
describe file(intf_dir) do
  it { should be_directory }
end

# Should exist
%w( eth0 lo ).each do |intf|
  describe file("#{intf_dir}/#{intf}") do
    it { should be_file }
  end
end

(1..10).each do |intn|
  describe file("#{intf_dir}/swp#{intn}") do
    it { should be_file }
  end
end

# Should not have been created by interface_policy
describe file("#{intf_dir}/swp20") do
  it { should_not be_file }
end

# Should have been removed by interface_policy
describe file("#{intf_dir}/swp99") do
  it { should_not be_file }
end

# Should have been configured by interface
describe file("#{intf_dir}/swp1") do
  its(:content) { should match(/iface swp1/) }
end

describe file("#{intf_dir}/swp2") do
  its(:content) { should match(/iface swp2 inet static/) }
  its(:content) { should match(/address 192.168.200.1/) }
  its(:content) { should match(/address 2001:db8:5678::/) }
  its(:content) { should match(/mtu 9000/) }
  its(:content) { should match(/bridge-vids 1-4094/) }
  its(:content) { should match(/bridge-pvid 1/) }
  its(:content) { should match(/bridge-access 2/) }
  its(:content) { should match(/link-speed 1000/) }
  its(:content) { should match(/link-duplex full/) }
  its(:content) { should match(/link-autoneg off/) }
  its(:content) { should match(/alias interface swp2/) }
  its(:content) { should match(/mstpctl-portnetwork yes/) }
  its(:content) { should match(/mstpctl-portadminedge yes/) }
  its(:content) { should match(/mstpctl-bpduguard yes/) }
  its(:content) { should match(/address-virtual 11:22:33:44:55:66 192.168.10.1/) }
  its(:content) { should match(/post-up ip route add 10.0.0.0\/8 via 192.168.200.2/) }
  its(:content) { should match(/post-up ip route add 172.16.0.0\/12 via 192.168.200.2/) }
  its(:content) { should match(/pre-down ip route del 10.0.0.0\/8 via 192.168.200.2/) }
  its(:content) { should match(/pre-down ip route del 172.16.0.0\/12 via 192.168.200.2/) }
end

# post_up should work as String as well as Array
describe file("#{intf_dir}/swp3") do
  its(:content) { should match(/iface swp3/) }
  its(:content) { should match(/post-up ip route add 192.168.0.0\/16 via 192.168.200.2/) }
  its(:content) { should match(/pre-down ip route del 192.168.0.0\/16 via 192.168.200.2/) }
  its(:content) { should match(/address-virtual 11:22:33:44:55:66 192.168.10.1/) }
end
