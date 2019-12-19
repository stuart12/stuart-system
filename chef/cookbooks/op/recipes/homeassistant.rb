ck = node['stuart']
activated = ck.dig('config', 'homeassistant', 'activate')

%w[evtest python3 python3-venv python3-pip libffi-dev libssl-dev].each do |pkg|
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
    action activated ? :create : :nothing
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

if node['secrets'] || activated
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
end

cookbook_file "#{config}/configuration.yaml" do
  user 'root'
  mode 0o444
  source "#{node.name}.yaml"
  action activated ? :create : :delete
  force_unlink true # https://github.com/chef/chef/issues/4992
  manage_symlink_source false
  notifies :restart, 'systemd_unit[homeassistant.service]' if activated
end

gitdir = ck['config']['git-stuart']['root']
path = (['python-scripts', 'delcom-clock'].map { |v| ::File.join(gitdir, v) } + [
  '/usr/local/sbin',
  '/usr/local/bin',
  '/usr/sbin',
  '/usr/bin',
  '/sbin',
  '/bin',
]).join(':')
# version = 'VERSION===0.79.3'
version = ''
unit_service = {
  User: user,
  Group: user,
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
udev = []
allow = []
if ck.dig('config', 'homeassistant', 'keyboard')
  unit_service[:DevicePolicy] = 'auto'
  allow << 'char-input rw'
  udev << '99-userdev-input'
end
if ck.dig('config', 'homeassistant', 'blinksticklight')
  unit_service[:DevicePolicy] = 'auto'
  allow << 'char-usb_device rwm'
  udev << '85-blinkstick'
end
if ck.dig('config', 'homeassistant', 'audio')
  unit_service[:DevicePolicy] = 'auto'
  allow << 'char-alsa rwm'
  unit_service[:SupplementaryGroups] = 'audio'
end
unit_service[:DeviceAllow] = allow

udev.map { |v| ::File.join('/etc/udev/rules.d', "#{v}.rules") }.each do |fn|
  template fn do
    user 'root'
    mode 0o644
    variables(group: user)
    action activated ? :create : :delete
    notifies :restart, 'systemd_unit[homeassistant.service]' if activated
  end
end
requires = ['mosquitto.service']
systemd_unit 'homeassistant.service' do
  action activated ? %w[create enable start] : %w[stop delete]
  content(
    Unit: {
      Description: 'Home Assistant',
      After: ['network-online.target'] + requires,
      Wants: 'network-online.target',
      Requires: requires,
    },
    Service: unit_service,
    Install: {
      WantedBy: 'multi-user.target',
    },
  )
  notifies :restart, 'systemd_unit[homeassistant.service]' if activated
  subscribes :restart, 'file[/etc/timezone]'
  subscribes :restart, 'link[/etc/localtime]'
end
