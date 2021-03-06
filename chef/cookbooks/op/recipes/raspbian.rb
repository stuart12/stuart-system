config = CfgHelper.config

return unless platform? 'raspbian'

ohai 'reload' do
  action :nothing
end

link '/etc/localtime' do
  # use timezone resource in Chef Client 14.6
  to "/usr/share/zoneinfo/#{config['timezone']['name']}"
  notifies :reload, 'ohai[reload]', :immediately
end
file '/etc/timezone' do
  content "#{config['timezone']['name']}\n"
  user 'root'
  mode 0o644
  notifies :reload, 'ohai[reload]', :immediately
end

::File.join(config['git']['directory'], 'github.com/stuart12').tap do |dir|
  repos = (config.dig('git', 'stuart12') || {}).select { |_, v| v }.keys
  directory dir do
    recursive true
    user 'root'
    mode 0o755
    not_if { repos.empty? }
  end
  repos.each do |repo|
    git ::File.join(dir, repo) do
      repository ::File.join('https://github.com/stuart12', repo)
      revision 'master'
      user 'root'
    end
  end
end

cookbook_file '/usr/local/bin/hw_params' do
  source 'hw_params.sh'
  user 'root'
  mode 0o755
end

systemd_unit 'systemd-timesyncd.service' do
  action %i[disable stop]
end

'/var/lib/vim/addons/after/plugin'.tap do |dir|
  directory dir do
    mode 0o755
    user 'root'
    recursive true
  end
  cookbook_file ::File.join(dir, 'chef.vim') do
    source 'vimrc.local'
    mode 0o644
    user 'root'
  end
end

cookbook_file '/etc/bash_completion.d/chef' do
  source 'bashrc'
  action :delete
end

package 'triggerhappy' do
  action :purge
end

(config.dig('users', 'users') || []).each do |user|
  user user do
    comment 'Managed by Chef'
    password config['users']['password'] || raise('no password configured')
    action :manage
  end
end

file '/etc/sudoers.d/010_chef' do
  content ['# Maintained by Chef', 'Defaults env_keep += "VISUAL"'].map { |v| "#{v}\n" }.join
  user 'root'
  mode 0o600
end

cookbook_file '/etc/default/keyboard'
