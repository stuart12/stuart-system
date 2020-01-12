name = 'snapclient'
return unless CfgHelper.activated? name
activated = true
config = CfgHelper.config[name] || {}

systemd_unit "#{name}.service" do
  action activated ? :enable : %i[stop disable]
end

template "/etc/default/#{name}" do
  variables(env: { 'SNAPCLIENT_OPTS' => "--hostID #{node.name}" })
  source 'etc_default.erb'
  mode 0o444
  user 'root'
  notifies(:restart, "systemd_unit[#{name}.service]", :delayed) if activated
  action activated ? :create : :delete
end

alsa_device = config['alsa_device']
alsa_cfg_dir = '/etc/alsa/conf.d'

[::File.dirname(alsa_cfg_dir), alsa_cfg_dir].each do |dname|
  directory dname do
    user 'root'
    mode 0o755
    action(activated && alsa_device ? :create : :nothing)
  end
end

template ::File.join(alsa_cfg_dir, '99-chef.conf') do
  source 'alsa.conf.erb'
  action(activated && alsa_device ? :create : :delete)
  variables(card: alsa_device)
  user 'root'
  mode 0o444
  notifies(:restart, "systemd_unit[#{name}.service]", :delayed) if activated
end
