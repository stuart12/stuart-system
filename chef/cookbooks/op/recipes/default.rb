package 'git'
package 'vim'
package 'snapclient'

hostname = 'bedroom'
ip = '192.168.0.25'
router = '192.168.0.254'
dns = '192.168.0.254'
mask = 24

ohai 'reload' do
  action :nothing
end

execute 'hostname' do
  command "hostname #{hostname}"
  not_if { hostname == node.name.split('.')[0] }
  notifies :reload, 'ohai[reload]'
  notifies :run, 'execute[hostname]'
  notifies :restart, 'systemd_unit[snapclient]'
end

file '/etc/hostname' do
  content "#{hostname}\n"
end

template '/etc/hosts' do
  source 'hostname.erb'
  variables hosts: {
    ip => hostname
  }
end
execute 'reload-systemd' do
  command 'systemctl daemon-reload'
  action :nothing
end

systemd_unit 'dhcpcd' do
  action :nothing
end

systemd_unit 'snapclient' do
  action :nothing
end

snapdir = '/etc/systemd/system/snapclient.service.d'
directory snapdir do
  recursive true
  user 'root'
  mode 0o755
end

cookbook_file ::File.join(snapdir, 'override.conf') do
  source 'snapclient.service.d'
  notifies :run, 'execute[reload-systemd]'
  notifies :restart, 'systemd_unit[snapclient]'
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
    mask: mask
  )
  user 'root'
  mode 0o644
  notifies :restart, 'systemd_unit[dhcpcd]'
end

systemd_unit 'systemd-timesyncd.service' do
  action %i[disable stop]
end
package 'ntp'
