ck = node['stuart']

return unless platform? 'raspbian'

hostname = ck.dig('config', 'networking', 'hostname')
ip = ck.dig('config', 'networking', 'ip')
router = ck.dig('config', 'networking', 'gateway')
dns = ck.dig('config', 'networking', 'dns')
mask = ck.dig('config', 'networking', 'mask')

ohai 'reload' do
  action :nothing
end

execute 'hostname' do
  command "hostname #{hostname}"
  not_if { hostname == node.name.split('.')[0] }
  notifies :reload, 'ohai[reload]', :immediately
  notifies :run, 'execute[hostname]'
  not_if { hostname.nil? } # avoid WARN: only_if  block for ... did you mean to run a command?
end
file '/etc/hostname' do
  # use hostname resource in Chef 14.0
  content "#{hostname}\n"
  not_if { hostname.nil? }
end

link '/etc/localtime' do
  # use timezone resource in Chef Client 14.6
  to "/usr/share/zoneinfo/#{ck['config']['timezone']['name']}"
  notifies :reload, 'ohai[reload]', :immediately
end
file '/etc/timezone' do
  content "#{ck['config']['timezone']['name']}\n"
  user 'root'
  mode 0o644
  notifies :reload, 'ohai[reload]', :immediately
end

template '/etc/hosts' do
  source 'hostname.erb'
  variables hosts: {
    ip => hostname,
  }
  not_if { ip.nil? }
  not_if { hostname.nil? }
end

systemd_unit 'dhcpcd' do
  action :nothing
end

::File.join(ck['config']['git']['directory'], 'github.com/stuart12').tap do |dir|
  directory dir do
    recursive true
    user 'root'
    mode 0o755
  end
  ck['config']['git']['stuart12'].select { |_, v| v }.each_key do |repo|
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

template '/etc/dhcpcd.conf' do
  source 'dhcpcd.conf.erb'
  variables(
    ip: ip,
    router: router,
    dns: dns,
    mask: mask,
  )
  user 'root'
  mode 0o444
  notifies :restart, 'systemd_unit[dhcpcd]'
  not_if { ip.nil? }
  not_if { router.nil? }
  not_if { dns.nil? }
  not_if { mask.nil? }
end

systemd_unit 'systemd-timesyncd.service' do
  action %i[disable stop]
end

['profile.d/shell_global_profile.sh'].each do |path|
  cookbook_file ::File.join('/etc/', path) do
    mode 0o644
    user 'root'
  end
end

package 'vim'
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

cookbook_file '/etc/inputrc' do
  mode 0o644
  user 'root'
end

template '/etc/gitconfig' do
  user 'root'
  mode 0o644
  variables(
    name: ck['config']['git']['name'],
    email: ck['config']['git']['email'],
  )
end

execute 'locale-gen' do
  action :nothing
end
template '/etc/locale.gen' do
  variables(
    utf8: ck['config']['locale']['UTF-8'].select { |_, v| v }.keys,
  )
  notifies :run, 'execute[locale-gen]'
  mode 0o644
  user 'root'
end

cookbook_file '/etc/bash_completion.d/chef' do
  source 'bashrc'
  user 'root'
  mode 0o644
end

package 'triggerhappy' do
  action :purge
end

systemd_unit 'chef-client' do
  action %i[stop disable]
end

(ck.dig('config', 'user', 'users') || []).each do |user|
  user user do
    comment 'Managed by Chef'
    password node[ck]['config']['users']['password']
    action :manage
  end
end
