ck = node['stuart']
service = 'homeassistant'
activated = ck.dig('config', service, 'activate')
cfg = ck.dig('config', service)

user = cfg['user']
group = cfg['group']
root = cfg['root']
home = ::File.join(cfg['root'], service)
config = ::File.join(home, 'config')
cache = ::File.join(home, 'cache')

secrets = (node['secrets'] || {})['homeassistant'] || {}

user user do
  action activated ? :create : :remove
  system true
  manage_home false
  home '/nowhere/that/exists'
  comment 'Home Assistant'
  shell '/bin/false'
end

[root, home].each do |dir|
  directory dir do
    user 'root'
    mode 0o755
    action activated ? :create : :nothing
  end
end
[config, cache].each do |dir|
  directory dir do
    user user
    group group
    mode 0o755
    action activated ? :create : :delete
    recursive !activated
  end
end

systemd_unit "#{service}.service" do
  action :nothing
end

template ::File.join(config, 'secrets.yaml') do
  user 'root'
  group group
  mode 0o440
  variables(secrets: (secrets['default'] || {}).merge(secrets[node.name] || {}))
  action activated ? :create : :delete
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) if activated && !cfg['skip_restart']
end

::File.join(config, '.storage').tap do |storage|
  directory storage do
    user user
    group group
    mode 0o755
    action activated ? :create : :nothing
  end
  cookbook_file ::File.join(storage, 'auth') do
    user user
    group group
    mode 0o600
    action activated ? :create_if_missing : :delete
  end
end

yaml = cfg['yaml']
yaml_file = ::File.join(config, 'configuration.yaml')
cookbook_file yaml_file do
  user 'root'
  mode 0o444
  source "#{node.name}.yaml"
  action activated ? :create : :delete
  force_unlink true # https://github.com/chef/chef/issues/4992
  manage_symlink_source false
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) if activated && !cfg['skip_restart']
  not_if { yaml }
end
CfgHelper.set_config['homeassistant']['yaml']['homeassistant']['time_zone'] = CfgHelper.config['timezone']['name'] if yaml
template yaml_file do
  user 'root'
  mode 0o444
  variables(yaml: yaml.to_hash)
  source 'yaml.yaml.erb'
  action activated ? :create : :delete
  force_unlink true # https://github.com/chef/chef/issues/4992
  manage_symlink_source false
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) if activated && !cfg['skip_restart']
  only_if { yaml }
end
