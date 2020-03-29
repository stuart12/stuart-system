name = 'homeassistant'
return unless CfgHelper.activated? name

cfg = CfgHelper.attributes(
  [name],
  user: name,
  group: name,
  home: ::File.join('/srv', name),
)

group = cfg['group']
user = cfg['user']
home = cfg['home']
%w[
  evtest
  libffi-dev
  libssl-dev
  python3
  python3-pip
  python3-venv
  python3-wheel
].each do |pkg|
  CfgHelper.add_package pkg
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
  CfgHelper.add_package 'evtest'
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
    "sh -c '. ve/bin/activate && python3 -m pip install homeassistant#{version ? "===#{version}" : ''}'",
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
  ExecStart: "sh -c '. ve/bin/activate && exec hass -c #{::File.join(home, 'config')} --log-file /tmp/hass.log'",
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
  SupplementaryGroups:  groups.sort,
}

CfgHelper.attributes(
  ['systemd', 'units', "#{name}.service", 'content'],
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
