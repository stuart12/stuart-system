ck = 'stuart'

activated = node[ck]['config']['snapclient']['activate']

package 'snapclient' do
  action activated ? :upgrade : :remove
end

systemd_unit 'snapclient' do
  action :nothing
end

snapdir = '/etc/systemd/system/snapclient.service.d'
directory snapdir do
  recursive true
  user 'root'
  mode 0o755
  only_if { activated }
end

cookbook_file ::File.join(snapdir, 'override.conf') do
  source 'snapclient.service.d'
  notifies :run, 'execute[reload-systemd]' if activated
  notifies :restart, 'systemd_unit[snapclient]' if activated
  action activated ? :create : :delete
end