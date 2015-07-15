#
# Copyright 2011-2013, Dell
# Copyright 2013-2014, SUSE LINUX Products GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class LoggingController < BarclampController
  def export
    ctime=Time.now.strftime("%Y%m%d-%H%M%S")
    @file = "crowbar-logs-#{ctime}.tar.bz2"
    pid = fork do
      system("sudo", "-i", Crowbar::Path.libdir.join("gather_logs.sh").expand_path.to_s, @file)
    end
    Process.detach(pid) # reap child process automatically; don't leave running    
    redirect_to "/utils?waiting=true&file=#{@file.gsub(/\./,'-DOT-')}"
  end

  protected

  def initialize_service
    @service_object = LoggingService.new logger
  end
end
