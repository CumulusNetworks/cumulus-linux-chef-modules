# Copyright 2015, Cumulus Networks
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
actions :create
default_action :create

attribute :name, kind_of: String, name_attribute: true
attribute :ipv4, kind_of: Array, default: []
attribute :ipv6, kind_of: Array, default: []
attribute :addr_method, kind_of: [String, NilClass]
attribute :ports, kind_of: Array, required: true
attribute :mtu, kind_of: [Integer, NilClass]
attribute :stp, kind_of: [TrueClass, FalseClass], default: true
attribute :mstpctl_treeprio, kind_of: [Integer, NilClass]
attribute :vlan_aware, kind_of: [TrueClass, FalseClass], default: false
attribute :alias_name, kind_of: [String, NilClass]
attribute :virtual_ip, kind_of: [String, NilClass]
attribute :virtual_mac, kind_of: [String, NilClass]
attribute :vids, kind_of: [Array, NilClass]
attribute :pvid, kind_of: [Integer, NilClass]
attribute :location, kind_of: String, default: node['cumulus']['interfaces']['dir']
attribute :post_up, kind_of: [String, Array, NilClass]
attribute :pre_down, kind_of: [String, Array, NilClass]
attribute :mcsnoop, kind_of: [TrueClass, FalseClass], default: false
