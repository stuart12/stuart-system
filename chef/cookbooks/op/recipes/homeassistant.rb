ck = 'stuart'
activated = node[ck]['config']['homeassistant']['activate']

%w[python3 python3-venv python3-pip libffi-dev libssl-dev].each do |pkg|
  package pkg do
    action activated ? :upgrade : :nothing
  end
end

service = 'homeassistant'
user = 'homeassistant'
root = '/srv'
home = ::File.join(root, service)
config = ::File.join(home, 'config')
cache = ::File.join(home, 'cache')

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
  end
end
[config, cache].each do |dir|
  directory dir do
    user user
    group user
    mode 0o755
    action activated ? :create : :delete
    recursive !activated
  end
end

template '/etc/udev/rules.d/85-blinkstick.rules' do
  user 'root'
  mode 0o644
  variables(group: user)
  action activated ? :create : :delete
  notifies :restart, 'systemd_unit[homeassistant.service]' if activated
end

template ::File.join(config, 'secrets.yaml') do
  user 'root'
  group user
  mode 0o440
  variables(
    secrets: node['secrets']['homeassistant']['secrets'],
  )
  action activated ? :create : :delete
  notifies :restart, 'systemd_unit[homeassistant.service]' if activated
end
cookbook_file "#{config}/configuration.yaml" do
  user 'root'
  mode 0o444
  source "#{node.name}.yaml"
  action activated ? :create : :delete
  notifies :restart, 'systemd_unit[homeassistant.service]' if activated
end

path = [
  '/opt/github.com/stuart12/python-scripts',
  '/opt/github.com/stuart12/delcom-clock',
  '/usr/local/sbin',
  '/usr/local/bin',
  '/usr/sbin',
  '/usr/bin',
  '/sbin',
  '/bin',
].join(':')
# version = 'VERSION===0.79.3'
version = ''
unit_service = {
  User: user,
  Group: user,
  SupplementaryGroups: 'audio',
  RuntimeDirectory: '%N',
  WorkingDirectory: '/tmp',
  StandardOutput: 'journal',
  StandardError: 'journal',
  Environment: [
    'HOME=/tmp',
    # "SRV=#{srv}',
    "PATH=#{path}",
    "XDG_CACHE_HOME=#{cache}",
  ],
  # https://www.home-assistant.io/docs/installation/raspberry-pi/',
  ExecStartPre: [
    '/usr/bin/python3 -m venv ve',
    "/bin/sh -c '. ve/bin/activate && python3 -m pip install wheel'",
    "/bin/sh -c '. ve/bin/activate && python3 -m pip install homeassistant#{version}'",
  ],
  ExecStart: "/bin/sh -c '. ve/bin/activate && exec hass -c #{config} --log-file /dev/null'",
  TimeoutStartSec: '22min',
  ReadWritePaths: home,
  ProtectHome: true,
  PrivateUsers: true,
  PrivateTmp: true,
  CapabilityBoundingSet: '',
  NoNewPrivileges: true,
  DevicePolicy: 'closed',
  ProtectControlGroups: true,
  ProtectKernelModules: true,
  ProtectKernelTunables: true,
  ProtectSystem: 'strict',
  RestrictAddressFamilies: 'AF_UNIX AF_INET AF_INET6 AF_NETLINK',
}
if node[ck]['config']['homeassistant']['keyboard']
  unit_service[:DevicePolicy] = 'auto'
  unit_service[:DeviceAllow] = 'char-input rw'
end
if node[ck]['config']['homeassistant']['blinksticklight']
  unit_service[:DevicePolicy] = 'auto'
  unit_service[:DeviceAllow] = 'char-usb_device rwm'
end
if node[ck]['config']['homeassistant']['audio']
  unit_service[:DevicePolicy] = 'auto'
  unit_service[:DeviceAllow] = 'char-alsa rwm'
end

systemd_unit 'homeassistant.service' do
  action activated ? %w[create enable start] : %w[stop delete]
  content(
    Unit: {
      Description: 'Home Assistant',
      After: 'network-online.target',
      Wants: 'network-online.target',
    },
    Service: unit_service,
    Install: {
      WantedBy: 'multi-user.target',
    },
  )
end