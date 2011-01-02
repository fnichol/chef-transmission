#
# Cookbook Name:: transmission
# Recipe:: daemon
#
# Copyright 2011, Fletcher Nichol
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

if platform?("redhat","centos","debian","ubuntu")
  include_recipe "iptables"
end

package "transmission-daemon"

service "transmission-daemon" do
  supports :restart => true, :reload => true
  action :enable
end

ruby_block "stop_transmission_daemon" do
  block do ; end
  unless node[:transmission][:daemon][:settings].empty?
    notifies :stop, "service[transmission-daemon]", :immediately
  end
end

ruby_block "update_settings" do
  block do
    settings = node[:transmission][:daemon][:settings]
    json_file = "/etc/transmission-daemon/settings.json"

    # only process settings if any are defined
    unless settings.empty?
      contents = File.open(json_file, "rb") { |f| f.read }
      json = JSON.parse(contents)

      # update settings that are "new"
      dirty = false
      settings.each_pair do |key, value|
        if json[key.to_s] != value
          json[key.to_s] = value
          dirty = true
        end
      end

      # write the updated settings file if any settings were updated
      if dirty
        File.open(json_file, 'w') {|f| f.write(JSON.pretty_generate(json)) }
      end
    end
  end

  unless node[:transmission][:daemon][:settings].empty?
    notifies :start, "service[transmission-daemon]", :immediately
  end
end

file "/etc/transmission-daemon/settings.json" do
  owner "debian-transmission"
  group "debian-transmission"
  mode  "0600"
end

if platform?("redhat","centos","debian","ubuntu")
  iptables_rule "port_transmission_daemon" do
    if node[:transmission][:daemon][:iptables_allow] == "disable"
      enable false
    else
      enable true
    end
  end
end
