ck = node['stuart']
service = 'homeassistant'
return unless CfgHelper.activated? service
activated = true
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

yaml_file = ::File.join(config, 'configuration.yaml')
use_file = cfg['use_config_file']
cookbook_file yaml_file do
  user 'root'
  mode 0o444
  source "#{node.name}.yaml"
  action activated ? :create : :delete
  force_unlink true # https://github.com/chef/chef/issues/4992
  manage_symlink_source false
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) if activated && !cfg['skip_restart']
  only_if { use_file }
end
template yaml_file do
  user 'root'
  mode 0o444
  variables(yaml: cfg['configuration'].to_hash, includes: %w[script switch sensor automation shell_command])
  source 'yaml.yaml.erb'
  action activated ? :create : :delete
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) if activated && !cfg['skip_restart']
  not_if { use_file }
end

automation = (cfg['automation'] || {}).sort.map { |a, action| { 'alias' => a }.merge(action.to_h) }

template ::File.join(config, 'automation.yaml') do
  user 'root'
  mode 0o444
  variables(yaml: automation)
  source 'yaml.yaml.erb'
  action activated ? :create : :delete
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) if activated && !cfg['skip_restart']
  not_if { use_file }
end

sensor = (cfg['sensor'] || {}).sort.map { |name, scfg| { 'name' => name }.merge(scfg.to_h) }

template ::File.join(config, 'sensor.yaml') do
  user 'root'
  mode 0o444
  variables(yaml: sensor)
  source 'yaml.yaml.erb'
  action activated ? :create : :delete
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) if activated && !cfg['skip_restart']
  not_if { use_file }
end

%w[script shell_command].each do |what|
  template ::File.join(config, "#{what}.yaml") do
    user 'root'
    mode 0o444
    variables(yaml: (cfg[what] || {}).to_h.sort.to_h)
    source 'yaml.yaml.erb'
    action activated ? :create : :delete
    notifies(:restart, "systemd_unit[#{service}.service]", :delayed) if activated && !cfg['skip_restart']
    not_if { use_file }
  end
end

switches = (cfg['switch'] || {}).sort.map { |v, k| { 'platform' => v, 'switches' => k.to_h } }

template ::File.join(config, 'switch.yaml') do
  user 'root'
  mode 0o444
  variables(yaml: switches)
  source 'yaml.yaml.erb'
  action activated ? :create : :delete
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) if activated && !cfg['skip_restart']
  not_if { use_file }
end
