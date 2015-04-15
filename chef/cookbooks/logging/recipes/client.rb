# Copyright 2011, Dell
# Copyright 2014, SUSE Linux GmbH.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

return if node[:platform] == "windows"

package "rsyslog"

logging_settings = CrowbarConfig.fetch("core", "logging")
servers = logging_settings.fetch("internal_servers", [])

# Disable syslogd in favor of rsyslog on redhat.
case node[:platform]
when "redhat","centos"
  service "syslog" do
    action [ :stop, :disable]
  end
when "suse"
  ruby_block "edit sysconfig syslog" do
    block do
      rc = Chef::Util::FileEdit.new("/etc/sysconfig/syslog")
      rc.search_file_replace_line(/^SYSLOG_DAEMON=/, "SYSLOG_DAEMON=rsyslogd")
      rc.write_file
    end
    # SLE12 already defaults to rsyslog
    only_if { node[:platform_version].to_f < 12.0 }
  end
end

service "rsyslog" do
  provider Chef::Provider::Service::Upstart if node[:platform] == "ubuntu"
  service_name "syslog" if node[:platform] == "suse" && node[:platform_version].to_f < 12.0
  supports :restart => true, :status => true, :reload => true
  running true
  enabled true
  action [ :enable, :start ]
end

if File.exists? "/etc/rsyslog.d/10-crowbar-client.conf"
  # Upgrade path: we used to create that file
  file "/etc/rsyslog.d/10-crowbar-client.conf" do
    action :delete
  end
end

template "/etc/rsyslog.d/99-crowbar-client.conf" do
  owner "root"
  group "root"
  mode 0644
  source "rsyslog.client.erb"
  variables(:servers => servers)
  notifies :restart, "service[rsyslog]"
end

