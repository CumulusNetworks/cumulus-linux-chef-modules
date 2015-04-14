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
  directory '/etc/cumulus' do
    action :create
  end

  port = template '/etc/cumulus/ports.conf' do
    cookbook 'cumulus'
    source 'ports.erb'
    variables(
      speed_10g: Cumulus::Utils.expand_port_list(new_resource.speed_10g),
      speed_40g: Cumulus::Utils.expand_port_list(new_resource.speed_40g),
      speed_40g_div_4: Cumulus::Utils.expand_port_list(new_resource.speed_40g_div_4),
      speed_4_by_10g: Cumulus::Utils.expand_port_list(new_resource.speed_4_by_10g)
    )
    owner 'root'
    group 'root'
    mode '0600'
    backup false
  end
  new_resource.updated_by_last_action(port.updated_by_last_action?)
end
