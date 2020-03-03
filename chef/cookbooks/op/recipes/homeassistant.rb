service = 'homeassistant'
return unless CfgHelper.activated? service
cfg = CfgHelper.config[service]

user = cfg['user']
group = cfg['group']
home = cfg['home']
config = ::File.join(home, 'config')
cache = ::File.join(home, 'cache')

secrets = (node['secrets'] || {})['homeassistant'] || {}

user user do
  system true
  manage_home false
  home '/nowhere/that/exists'
  comment 'Home Assistant'
  shell '/bin/false'
end

directory home do
  user 'root'
  recursive true
  mode 0o755
end
[config, cache].each do |dir|
  directory dir do
    user user
    group group
    mode 0o755
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
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) unless cfg['skip_restart']
end

::File.join(config, '.storage').tap do |storage|
  directory storage do
    user user
    group group
    mode 0o755
  end
  cookbook_file ::File.join(storage, 'auth') do
    user user
    group group
    mode 0o600
    action :create_if_missing
  end
end

yaml_file = ::File.join(config, 'configuration.yaml')
use_file = cfg['use_config_file']
cookbook_file yaml_file do
  user 'root'
  mode 0o444
  source "#{node.name}.yaml"
  force_unlink true # https://github.com/chef/chef/issues/4992
  manage_symlink_source false
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) unless cfg['skip_restart']
  only_if { use_file }
end
template yaml_file do
  user 'root'
  mode 0o444
  variables(yaml: cfg['configuration'].to_hash, includes: %w[script switch sensor automation shell_command])
  source 'yaml.yaml.erb'
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) unless cfg['skip_restart']
  not_if { use_file }
end

automation = (cfg['automation'] || {}).sort.map { |a, action| { 'alias' => a }.merge(action.to_h) }

template ::File.join(config, 'automation.yaml') do
  user 'root'
  mode 0o444
  variables(yaml: automation)
  source 'yaml.yaml.erb'
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) unless cfg['skip_restart']
  not_if { use_file }
end

sensor = (cfg['sensor'] || {}).sort.map { |name, scfg| { 'name' => name }.merge(scfg.to_h) }

template ::File.join(config, 'sensor.yaml') do
  user 'root'
  mode 0o444
  variables(yaml: sensor)
  source 'yaml.yaml.erb'
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) unless cfg['skip_restart']
  not_if { use_file }
end

%w[script shell_command].each do |what|
  template ::File.join(config, "#{what}.yaml") do
    user 'root'
    mode 0o444
    variables(yaml: (cfg[what] || {}).to_h.sort.to_h)
    source 'yaml.yaml.erb'
    notifies(:restart, "systemd_unit[#{service}.service]", :delayed) unless cfg['skip_restart']
    not_if { use_file }
  end
end

switches = (cfg['switch'] || {}).sort.map { |v, k| { 'platform' => v, 'switches' => k.to_h } }

template ::File.join(config, 'switch.yaml') do
  user 'root'
  mode 0o444
  variables(yaml: switches)
  source 'yaml.yaml.erb'
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) unless cfg['skip_restart']
  not_if { use_file }
end

template ::File.join(config, 'options.xml') do
  user 'root'
  mode 0o444
  # https://github.com/OpenZWave/open-zwave/wiki/Config-Options
  variables(
    options: {
      Associate: true,
      DriverMaxAttempts: 5,
      Logging: true,
      NotifyTransactions: false,
      RefreshAllUserCodes: false,
      SaveConfiguration: true,
      SaveLogLevel: 5, # Alert Messages and Higher
      ThreadTerminateTimeout: 5000,
    },
  )
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) unless cfg['skip_restart']
  only_if { cfg['z-wave'] }
end
