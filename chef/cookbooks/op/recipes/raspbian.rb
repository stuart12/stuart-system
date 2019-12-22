ck = 'stuart'

return unless platform? 'raspbian'

hostname = node[ck]['config']['networking']['hostname']
ip = node[ck]['config']['networking']['ip']
router = node[ck]['config']['networking']['gateway']
dns = node[ck]['config']['networking']['dns']
mask = node[ck]['config']['networking']['mask']

ohai 'reload' do
  action :nothing
end

execute 'hostname' do
  command "hostname #{hostname}"
  not_if { hostname == node.name.split('.')[0] }
  notifies :reload, 'ohai[reload]', :immediately
  notifies :run, 'execute[hostname]'
end
file '/etc/hostname' do
  # use hostname resource in Chef 14.0
  content "#{hostname}\n"
end

link '/etc/localtime' do
  # use timezone resource in Chef Client 14.6
  to "/usr/share/zoneinfo/#{node[ck]['config']['timezone']['name']}"
  notifies :reload, 'ohai[reload]', :immediately
end
file '/etc/timezone' do
  content "#{node[ck]['config']['timezone']['name']}\n"
  user 'root'
  mode 0o644
  notifies :reload, 'ohai[reload]', :immediately
end

template '/etc/hosts' do
  source 'hostname.erb'
  variables hosts: {
    ip => hostname,
  }
end
execute 'reload-systemd' do
  command 'systemctl daemon-reload'
  action :nothing
end

systemd_unit 'dhcpcd' do
  action :nothing
end

::File.join(node[ck]['config']['git']['directory'], 'github.com/stuart12').tap do |dir|
  directory dir do
    recursive true
    user 'root'
    mode 0o755
  end
  node[ck]['config']['git']['stuart12'].select { |_, v| v }.each_key do |repo|
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
  mode 0o644
  notifies :restart, 'systemd_unit[dhcpcd]'
end

systemd_unit 'systemd-timesyncd.service' do
  action %i[disable stop]
end
package 'ntp'

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
    name: node[ck]['config']['git']['name'],
    email: node[ck]['config']['git']['email'],
  )
end

execute 'locale-gen' do
  action :nothing
end
template '/etc/locale.gen' do
  variables(
    utf8: node[ck]['config']['locale']['UTF-8'].select { |_, v| v }.keys,
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

node['secrets'].dig('users').each do |user, cfg|
  user user do
    password cfg['password'] if cfg['password']
    action :manage
  end
end
