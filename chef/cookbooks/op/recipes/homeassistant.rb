service = 'homeassistant'
return unless CfgHelper.activated? service

cfg = CfgHelper.attributes(
  [service],
  user: service,
  group: service,
  home: ::File.join('/srv', service),
)

user = cfg['user']
group = cfg['group']
home = cfg['home']
config = ::File.join(home, 'config')
cache = ::File.join(home, 'cache')

secrets = (node['secrets'] || {})[service] || {}

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
def fix_sensors(cfg)
  (cfg || {})
    .reject { |_, cfg2| cfg2.nil? }
    .transform_keys(&:to_s)
    .sort
    .map { |name, scfg| { 'name' => name } .merge(scfg.to_h) }
end

def sensors(cfg)
  fix_sensors(cfg['sensor']) <<
    {
      platform: 'template',
      sensors: cfg['template_sensor'],
    }
end

includes = CfgHelper.attributes(
  [service, 'includes'],
  {
    automation: { contents: (cfg['automation'] || {}).sort.map { |a, action| { 'alias' => a }.merge(action.to_h) } },
    script: { contents: cfg['script'] },
    # history_graph: { contents: cfg['history_graph'] },
    shell_command: { contents: cfg['shell_command'] },
    binary_sensor: { contents: fix_sensors(cfg['binary_sensor']) },
    sensor: { contents: sensors(cfg) },
    media_player:
    { secret: true,
      contents: (cfg['media_player'] || {})
      .select { |_, c| c['platform'] }
      .values
      .sort { |a, b| a['platform'] <=> b['platform'] } },
    switch: { contents: (cfg['switch'] || {}).sort.map { |v, k| { 'platform' => v, 'switches' => k.to_h } } },
  },
)

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
  variables(yaml: cfg['configuration'].to_hash, includes: includes.keys)
  source 'yaml.yaml.erb'
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) unless cfg['skip_restart']
  not_if { use_file }
end

includes.each do |name, icfg|
  template ::File.join(config, "#{name}.yaml") do
    user 'root'
    group group
    mode icfg['secret'] ? 0o440 : 0o444
    variables yaml: icfg['contents']
    source 'yaml.yaml.erb'
    notifies(:restart, "systemd_unit[#{service}.service]", :delayed) unless cfg['skip_restart']
    not_if { use_file }
  end
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

%w[
  evtest
  libffi-dev
  libssl-dev
  python3
  python3-pip
  python3-venv
  python3-wheel
].each do |pkg|
  paquet pkg
end
path = [
  CfgHelper.git_stuart('python-scripts'),
  CfgHelper.git_stuart('delcom-clock'),
  '/usr/local/sbin',
  '/usr/local/bin',
  '/usr/sbin',
  '/usr/bin',
  '/sbin',
  '/bin',
].join(':')
allow = []
groups = []
if cfg.dig('audio')
  allow << 'char-alsa rwm'
  groups << 'audio'
end
if cfg.dig('keyboard')
  paquet 'evtest'
  allow << 'char-input rw'
  groups << 'input'
end
if cfg.dig('IR')
  allow << '/dev/lirc0 rw'
  groups << 'video'
end
if cfg.dig('z-wave')
  CfgHelper.attributes(%w[boot config options enable_uart], 1)
  allow << '/dev/z-wave rw'
  CfgHelper.attributes(
    ['udev', 'rules', name, 'rules', 'z-wave'],
    [
      'SUBSYSTEM=="tty"',
      'ATTRS{idProduct}=="0002"',
      'ATTRS{idVendor}=="1d6b"',
      'SYMLINK+="z-wave"',
      "GROUP=\"#{group}\"",
    ],
  )
end
if cfg.dig('blinksticklight')
  allow << 'char-usb_device rwm'
  CfgHelper.attributes(
    ['udev', 'rules', name, 'rules', 'blinksticklight'],
    [
      'SUBSYSTEM=="usb"',
      'ATTR{product}=="BlinkStick"',
      'ATTR{idVendor}=="20a0"',
      'ATTR{idProduct}=="41e5"',
      'MODE="0660"',
      "GROUP=\"#{group}\"",
    ],
  )
end
version = cfg['version']

def led(on)
  led = '/sys/class/leds/led1/brightness'
  return [] unless ::File.exist? led

  ["+sh -c 'echo #{on ? 255 : 0} > #{led}'"]
end

exec_start_pre =
  led(true) +
  [
    'python3 -m venv ve',
    "sh -c '. ve/bin/activate && python3 -m pip install wheel'",
    "sh -c '. ve/bin/activate && python3 -m pip install --no-use-pep517 homeassistant#{version ? "===#{version}" : ''}'",
  ]

unit_service = {
  User: user,
  Group: group,
  RuntimeDirectory: '%N',
  WorkingDirectory: '/tmp',
  Environment: [
    'HOME=/tmp',
    "PATH=#{path}",
    "XDG_CACHE_HOME=#{::File.join(home, 'cache')}",
  ],
  # https://www.home-assistant.io/docs/installation/raspberry-pi/',
  ExecStartPre: exec_start_pre,
  ExecStart: "sh -c '. ve/bin/activate && exec hass -c #{::File.join(home, 'config')} --log-file /dev/null'",
  ExecStartPost: led(false),
  TimeoutStartSec: '22min',
  ReadWritePaths: home,
  ProtectHome: true,
  PrivateUsers: true,
  PrivateTmp: true,
  CapabilityBoundingSet: '',
  NoNewPrivileges: true,
  ProtectControlGroups: true,
  ProtectKernelModules: true,
  ProtectKernelTunables: true,
  ProtectSystem: 'strict',
  RestrictAddressFamilies: 'AF_UNIX AF_INET AF_INET6 AF_NETLINK',
  DevicePolicy: allow.empty? ? 'closed' : 'auto',
  DeviceAllow: allow.sort,
  SupplementaryGroups: groups.sort,
}

content = CfgHelper.attributes(
  [service, 'systemd'],
  Unit: {
    Description: 'Home Assistant',
    After: ['network-online.target', 'mosquitto.service'],
    Wants: 'network-online.target',
  },
  Service: unit_service,
  Install: {
    WantedBy: 'multi-user.target',
  },
)
systemd_unit "#{service}.service" do
  action %i[create start enable]
  content content
  notifies :restart, "systemd_unit[#{service}.service]", :delayed
end
