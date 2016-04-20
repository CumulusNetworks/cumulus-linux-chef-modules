Cumulus Cookbook
=============
This cookbook contains LWRP's and libraries for configring and managing components of Cumulus Linux in a modular manner.


Attributes
----------
#### cumulus::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['cumulus']['interfaces']['dir']</tt></td>
    <td>String</td>
    <td>Path to the network interfaces configuration fragments</td>
    <td><tt>/etc/network/interfaces.d/</tt></td>
  </tr>
</table>

Usage
-----
### Recipes
-----
#### cumulus::switchd

Provides a Chef service resource for the Cumulus Networks switchd daemon.

On its own this recipe does nothing, but can be used with the Cumulus resource providers to restart switchd when the systemc configuration changes.

#### cumulus::interfaces

Provides a Chef service resource for the networking service, and configures the system for network interfaces configuration fragments.

By default the recipe creates the fragments directory specifed in `node['cumulus']['interfaces']['dir']` attribute, then uses `ifquery` to extract the current configuration for the `eth0` and `lo` interfaces. The current `/etc/network/interfaces` file is then over-written with one that uses configuration fragments.

This recipe is intended to be used with the `cumulus_interfaces_policy` and `cumulus_interface`, `cumulus_bridge` & `cumulus_bond` providers to manage your network interfaces. Used alone it will over-write any existing configuration in the `/etc/network/interfaces` file.

#### cumulus::default

Includes both the `interfaces` & `switchd` recipes. 
Just include `cumulus` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[cumulus]"
  ]
}
```

### Definitions
----
#### cumulus_ports

Configure the switch ports attributes.

##### Parameters:

* `name` - Name for the resource. This is not directly used by the provider.
* `speed_10g` - Array of ports to be configured for 10GbE.
* `speed_40g ` - Array of ports to be configured for 40GbE.
* `speed_40_div_4` - Array of ports to be configured for 40GbE split to 4 x 10GbE.
* `speed_4_by_10g` - Array of ports to be configured for 10GbE to be aggregated into 1 x 40GbE.

##### Examples:

Configure `swp5` through `swp48` as 10GbE ports, `swp49` & `swp51` through `swp52` as 40GbE ports, `swp1` through `swp4` as 4 x 10GbE ports and `swp50` as 1 x 40GbE aggregate ports.

```ruby
cumulus_ports 'speeds' do
  speed_10g ['swp5-48']
  speed_40g ['swp49','swp51-52']
  speed_40g_div_4 ['swp1-4']
  speed_4_by_10g ['swp50']
  notifies :restart, "service[switchd]"
end
```

#### cumulus_license

Installs a Cumulus Linux license file on a Cumulus Linux switch.

If a license is already installed the provider will check that it has expired before replacing it. You can over-ride this behaviour with the `force` parameter.

The provider uses the `cl-license` command to validate and install the license file.

##### Parameters:

* `name` - Name for the resource. This is not directly used by the provider.
* `source` - URL to the license file to be installed.
* `force` - If `true`, skip the license expiration check and install the new license regardless of any current license. Default is `false`.

##### Examples:

Install a license file if one is not already installed:

```ruby
cumulus_license 'example' do
  source 'http://example.com/cumulus.lic'
  notifies :restart, "service[switchd]"
end
```

Install a license file, over-writting any existing license:

```ruby
cumulus_license 'example' do
  source 'http://example.com/cumulus.lic'
  force true
  notifies :restart, "service[switchd]"
end
```

#### cumulus_interface_policy

Manage the interface configuration snippets. The provided list of interfaces is compared to the contents of the configuration directory. Any configuration files which exist on disk but are not in the list of interfaces are deleted. This allows you to ensure that no unmanaged interface configurations are installed.

Note that this includes interfaces such as `eth0` and `lo`, so these interfaces must be included in the `allowed` list or strange things may happen.

##### Parameters:

* `name` - Name for the resource. This is not directly used by the provider.
* `allowed` - Array of interface names that you are managing with Chef. Any configurations that are not listed will be deleted.
* `location` - Location of the configuration snippets directory. Default is the directory set by the `node['cumulus']['interfaces']['dir']` attribute.

##### Examples:

Manage `eth0`, `lo`, `swp1` though `swp32`, `bond0` through `bond25` and `br0`:

````ruby
cumulus_interface_policy 'policy' do
  allowed ['eth0', 'lo', 'swp1-32', 'bond0-25', 'br0']
  notifies :reload, "service[networking]"
end
````

#### cumulus_interface

Manage a network interface using the ifupdown2 `ifquery` tool. The configuration for the interface will be written to a fragment under the interface configurations fragments directory.

The cumulus_interface provider can be used to manage front panel ports, L3 bridge sub-interfaces, L3 physical or bond sub-interfaces, L2/L3 trunks and access ports, the loopback and management ports. For bridge or bond interfaces, see cumulus_bridge or cumulus_bond, below.

##### Parameters:

* `name` - Identifier for the interface.
* `ipv4` - Array of IPv4 addresses to be applied to the interface.
* `ipv6` - Array of IPv6 addresses to be applied to the interface.
* `alias_name` - Interface alias.
* `addr_method` - Address assignment method, `dhcp` or `loopback`. Default is empty, I.e. no address method is set.
* `speed` - The interface link speed.
* `mtu` - The interface Maximum Transmission Unit (MTU)
* `virtual_ip` - VRR virtual IP
* `virtual_mac` - VRR virtual MAC
* `vids` - Array of VLANs to be configured for a VLAN aware trunk interface.
* `pvid` - Native VLAN for a VLAN aware trunk interface.
* `post_up` - String or Array of post-up commands(s) to run.
* `pre_down` - String or Array of pre-down commands(s) to run.
* `location` - Location of the configuration snippets directory. Default is the directory set by the `node['cumulus']['interfaces']['dir']` attribute.
* `mstpctl_portnetwork` - Enable bridge assurance on a VLAN aware trunk.
* `mstpctl_bpduguard` - Enable BPDU guard on a VLAN aware trunk.
* `mstpctl_portadminedge` - Enables admin edge port.

The following CLAG related attributes are also available. If CLAG is enabled, `clagd_enable`, `clagd_priority`, `clagd_peer_ip` and `clagd_sys_mac` should all be provided:

* `clagd_enable` - Enable the clagd daemon.
* `clagd_priority` - Set the CLAG priority for this switch.
* `clagd_peer_ip` - Address of the CLAG peer switch.
* `clagd_sys_mac` - CLAG system MAC. The MAC must be identical on both of the CLAG peers.
* `clagd_args` - Any additional arguments to be passed to the clagd deamon.

##### Examples:

Configure the loopback interface and the management interface `eth0` using DHCP:

````ruby
cumulus_interface 'lo' do
  addr_method 'loopback'
end

cumulus_interface 'eth0' do
  addr_method 'dhcp'
end
````

Configure `swp33` as a 1GbE port with a single IPv4 address:

````ruby
cumulus_interface 'swp33' do
  ipv4 ['10.30.1.1/24']
  link_speed 1000
end
````

Configure the interface `peerlink.4094` as the CLAG peer interface:

````ruby
cumulus_interface 'peerlink.4094' do
  ipv4 ['10.100.1.0/31']
  clagd_enable true
  clagd_peer_ip '10.100.1.1/31'
  clagd_sys_mac '11:11:22:22:33:33'
end
````

#### cumulus_bond

Manage a network bond using the ifupdown2 `ifquery` tool. The configuration for the interface will be written to a fragment under the interface configurations fragments directory.

##### Parameters:

* `name` - Identifier for the bond interface.
* `slaves` - Bond members.
* `min_links` - Minimum number of slave links for the bond to be considered up. Default is `1`.
* `mode` - Bond mode. Default is `802.3ad`
* `miimon` - MII link monitoring interval. Default is `100`
* `xmit_hash_policy` - TX hashing policy. Default is `layer3+4`
* `lacp_rate` - LACP bond rate. Default is `1` I.e. fast LACP timeout.
* `ipv4` - Array of IPv4 addresses to be applied to the interface.
* `ipv6` - Array of IPv6 addresses to be applied to the interface.
* `alias_name` - Interface alias.
* `addr_method` - Address assignment method. May be `dhcp` or empty. Default is empty, I.e. no address method is set.
* `mtu` - The interface Maximum Transmission Unit (MTU)
* `virtual_ip` - VRR virtual IP
* `virtual_mac` - VRR virtual MAC
* `vids` - Array of VLANs to be configured for a VLAN aware trunk interface.
* `pvid` - Native VLAN for a VLAN aware trunk interface.
* `location` - Location of the configuration snippets directory. Default is the directory set by the `node['cumulus']['interfaces']['dir']` attribute.
* `mstpctl_portnetwork` - Enable bridge assurance on a VLAN aware trunk.
* `mstpctl_bpduguard` - Enable BPDU guard on a VLAN aware trunk.
* `mstpctl_portadminedge` - Enables admin edge port.
* `clag_id` - Define which bond is in the CLAG. The ID must be the same on both CLAG peers.

The following LACP bypass related attributes are also available. If LACP bypass is enabled, one of the `lacp_bypass_priority` or `lacp_bypass_all_active` attributes must be specified:

* `lacp_bypass_allow` - Enable LACP bypass
* `lacp_bypass_period` - LACP bypass period
* `lacp_bypass_priority` - Enable priority mode for LACP bypass
* `lacp_bypass_all_active` - Enable all-active mode for LACP bypass

##### Examples:

Create a bond called `peerlink` with the interfaces `swp1` and `swp2` as members:

````ruby
cumulus_bond 'peerlink' do
  slaves ['swp1-2']
end
````

Create a bond called `bond0` with the interfaces `swp3` and `swp4` as members, using layer2+3 TX hashing and the CLAG ID set:

````ruby
cumulus_bond 'bond0' do
  slaves ['swp3-4']
  xmit_hash_policy 'layer2+3'
  clag_id 1
end
````

#### cumulus_bridge

Manage a bridge using the ifupdown2 `ifquery` tool. The configuration for the interface will be written to a fragment under the interface configurations fragments directory.

The provider supports both "classic" and "VLAN aware" bridge driver models.

##### Parameters:

* `name` - Identifier for the bridge interface.
* `ipv4` - Array of IPv4 addresses to be applied to the interface.
* `ipv6` - Array of IPv6 addresses to be applied to the interface.
* `alias_name` - Interface alias.
* `addr_method` - Address assignment method. May be `dhcp` or empty. Default is empty, I.e. no address method is set.
* `mtu` - The interface Maximum Transmission Unit (MTU)
* `stp` - Enable spanning tree. Default is `true`.
* `mstpctl_treeprio` - Bridge tree root priority. Must be a multiple of 4096.
* `vlan_aware` - Use the VLAN aware bridge driver. Default is `false`
* `virtual_ip` - VRR virtual IP
* `virtual_mac` - VRR virtual MAC
* `vids` - Array of VLANs to be configured for a VLAN aware trunk interface.
* `pvid` - Native VLAN for a VLAN aware trunk interface.
* `location` - Location of the configuration snippets directory. Default is the directory set by the `node['cumulus']['interfaces']['dir']` attribute.

##### Examples:

"Classic" bridge driver:

````ruby
cumulus_bridge 'br10' do
  ports ['swp11-12.1', 'swp32.1']
  ipv4 ['10.1.1.1/24', '10.20.1.1/24']
  ipv6 ['2001:db8:abcd::/48']
  alias_name 'classic bridge'
  mtu 9000
  mstpctl_treeprio 4096
end
````

VLAN aware bridge:

````ruby
cumulus_bridge 'bridge' do
  vlan_aware true
  ports ['peerlink', 'downlink', 'swp10']
  vids ['1-4094']
  pvid 1
  stp true
  mstpctl_treeprio 4096
end
````

### Libraries
----
#### Util

The Cumulus::Util library is intended for use internally by the LWRPs. It is not intended for direct use by users, although the functions are fully documented. This library and the functions are subject to change at any time, with no notice.

Contributing
------------
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
* Author:: Cumulus Networks Inc.

* Copyright:: 2015 Cumulus Networks Inc.

Recipes are licensed under the Apache License, Version 2.0

All others are licensed under the GNU General Public License, Version 2.0

---

![Cumulus icon](http://cumulusnetworks.com/static/cumulus/img/logo_2014.png)

### Cumulus Linux

Cumulus Linux is a software distribution that runs on top of industry standard
networking hardware. It enables the latest Linux applications and automation
tools on networking gear while delivering new levels of innovation and
ﬂexibility to the data center.

For further details please see: [cumulusnetworks.com](http://www.cumulusnetworks.com)
