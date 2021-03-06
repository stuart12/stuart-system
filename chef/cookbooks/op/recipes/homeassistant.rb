service = 'homeassistant'
return unless CfgHelper.activated? service

cfg = CfgHelper.config([service])
user = cfg['user']
group = cfg['group']
home = cfg['home']
config = ::File.join(home, 'config')
cache = ::File.join(home, 'cache')
podhome = CfgHelper.activated?('hass_main') ? ::File.join(home, CfgHelper.attributes([service, 'podcasts'], 'podcasts')) : nil

secrets = (node['secrets'] || {})[service] || {}

package 'libopenjp2-7'

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

def sensors(cfg, prefix = '')
  templates = cfg["#{prefix}template_sensor"]
  fix_sensors(cfg["#{prefix}sensor"]) +
    if templates&.any?
      [{
        platform: 'template',
        sensors: templates.map { |name, v| [name.downcase.gsub(' ', '_'), { 'friendly_name' => name }.merge(v)] }.to_h,
      }]
    else
      []
    end
end

includes = CfgHelper.attributes(
  [service, 'includes'],
  automation: { contents: (cfg['automation'] || {}).sort.map { |a, action| { 'alias' => a }.merge(action.to_h) } },
  script: { contents: cfg['script'].map { |name, v| [name.downcase.gsub(' ', '_'), { 'alias' => name }.merge(v)] }.to_h },
  # history_graph: { contents: cfg['history_graph'] },
  shell_command: { contents: cfg['shell_command'] },
  binary_sensor: { contents: sensors(cfg, 'binary_') },
  sensor: { contents: sensors(cfg) },
  media_player:
  { secret: true,
    contents: (cfg['media_player'] || {})
    .select { |_, c| c['platform'] }
    .values
    .sort_by { |a| a['platform'] } },
  switch: { contents: (cfg['switch'] || {}).sort.map { |v, k| { 'platform' => v, 'switches' => k.to_h } } },
)

template ::File.join(config, 'configuration.yaml') do
  user 'root'
  mode 0o444
  variables(yaml: cfg['configuration'].to_hash, includes: includes.keys)
  source 'yaml.yaml.erb'
  notifies(:restart, "systemd_unit[#{service}.service]", :delayed) unless cfg['skip_restart']
end

includes.each do |name, icfg|
  template ::File.join(config, "#{name}.yaml") do
    user 'root'
    group group
    mode icfg['secret'] ? 0o440 : 0o444
    variables yaml: icfg['contents']
    source 'yaml.yaml.erb'
    notifies(:restart, "systemd_unit[#{service}.service]", :delayed) unless cfg['skip_restart']
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
allow << '/dev/z-wave rw' if cfg.dig('z-wave')
allow << 'char-usb_device rwm' if cfg.dig('blinksticklight')
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
    "sh -c '. ve/bin/activate && python3 -m pip install homeassistant#{version ? "===#{version}" : ''}'",
  ]

unit_service = {
  User: user,
  Group: group,
  RuntimeDirectory: '%N',
  WorkingDirectory: '/tmp',
  Environment: ([
    'HOME=/tmp',
    "PATH=#{path}",
    "XDG_CACHE_HOME=#{::File.join(home, 'cache')}",
  ] + (podhome ? ["PODCASTDIR=#{podhome}"] : [])).sort,
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
unit = "#{service}.service"
systemd_unit unit do # https://github.com/chef/chef/issues/5827
  content content
  action %i[create enable start]
  notifies :restart, "systemd_unit[#{unit}]", :delayed
end

if podhome
  directory podhome do
    mode 0o755
    owner 'root'
  end

  file ::File.join(podhome, 'podcasts') do
    mode 0o640
    group group
    owner 'root'
    content CfgHelper.secret(%w[radio podcasts]).sort.map { |l| "#{l}\n" }.join
  end

  file ::File.join(podhome, 'played') do
    mode 0o660
    group group
    owner 'root'
  end
end
