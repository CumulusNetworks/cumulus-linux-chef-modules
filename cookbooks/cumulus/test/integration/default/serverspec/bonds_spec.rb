require 'serverspec'

set :backend, :exec
set :path, '/bin:/usr/bin:/sbin/usr/sbin'

intf_dir = File.join('', 'etc', 'network', 'interfaces.d')

# Should have been created by the cumulus_bond resource
describe file("#{intf_dir}/bond0") do
  it { should be_file }
  its(:content) { should match(/iface bond0/) }
  its(:content) { should match(/bond-slaves glob swp1-2 swp4/) }
  its(:content) { should match(/bond-use-carrier 1/) }
  its(:content) { should match(/bridge-access 2/) }
end

describe file("#{intf_dir}/bond1") do
  it { should be_file }
  its(:content) { should match(/iface bond1 inet static/) }
  its(:content) { should match(/bond-slaves glob swp5-6/) }
  its(:content) { should match(/mtu 9000/) }
  its(:content) { should match(/bond-miimon 99/) }
  its(:content) { should match(/bond-lacp-rate 9/) }
  its(:content) { should match(/bond-lacp-bypass-allow 1/) }
  its(:content) { should match(/bond-lacp-bypass-period 30/) }
  its(:content) { should match(/bond-lacp-bypass-all-active 1/) }
  its(:content) { should match(/bond-min-links 2/) }
  its(:content) { should match(/bridge-vids 1 2 4-4094/) }
  its(:content) { should match(/bridge-pvid 1/) }
  its(:content) { should match(/alias bond number 1/) }
  its(:content) { should match(/bond-mode balance-alb/) }
  its(:content) { should match(/bond-xmit-hash-policy layer2/) }
  its(:content) { should match(/bond-use-carrier 1/) }
  its(:content) { should match(/address 192.168.1.0\/16/) }
  its(:content) { should match(/address 2001:db8:abcd::\/48/) }
  its(:content) { should match(/address-virtual 11:22:33:44:55:FF 192.168.20.1/) }
  its(:content) { should match(/mstpctl-portnetwork yes/) }
  its(:content) { should match(/mstpctl-portadminedge yes/) }
  its(:content) { should match(/mstpctl-bpduguard yes/) }
  its(:content) { should match(/post-up ip route add 10.0.0.0\/8 via 192.168.200.2/) }
  its(:content) { should match(/post-up ip route add 172.16.0.0\/12 via 192.168.200.2/) }
  its(:content) { should match(/pre-down ip route del 10.0.0.0\/8 via 192.168.200.2/) }
  its(:content) { should match(/pre-down ip route del 172.16.0.0\/12 via 192.168.200.2/) }
end
