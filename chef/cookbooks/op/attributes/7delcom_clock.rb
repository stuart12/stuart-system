ck = 'stuart'
name = 'delcom-clock'
activated = node[ck].dig('config', name, 'activate')
default[ck]['config']['git-stuart']['repos'][name] = true if activated
default[ck]['config']['packages']['install']['python3-paho-mqtt'] = true if activated

systemd_alias = "/dev/alias/#{name.tr('-', '_')}/"

unit = {
  BindsTo: "#{systemd_alias.sub('/', '').tr('/', '-')}%i.device",
  DefaultDependencies: false,
  StopWhenUnneeded: true,
}

if activated
  default[ck]['config']['udev']['rules'][name]['rules']['main'] = [
    'ACTION=="bind|unbind"',
    'ENV{PRODUCT}=="fc5/1227/*"',
    'ENV{DEVTYPE}=="usb_interface"',
    'TAG+="systemd"',
    "ENV{SYSTEMD_ALIAS}+=\"#{systemd_alias}%k\"",
    "ENV{SYSTEMD_WANTS}+=\"#{name}@$name.service\"",
    'PROGRAM="/usr/bin/logger -p notice %E{ACTION} delcom-clock name=$name k=%k n=%n p=%p b=%b driver=$driver N=%N"',
  ]
end

log_me = ["logger -p notice unit #{name} starting n=%n i=%i I=%I f=%f"]

chown = %w[../power/level powered mode_msb mode_lsb textmode text decimals]
devdir = '/sys/bus/usb/drivers/usbsevseg/%i'
control_setup = []

command = [
  ::File.join(node[ck]['config']['git-stuart']['root'], name, name),
  # '--verbose',
  '--loglevel=info',
  '--mode=666',
  '--update=60',
  '--pformat="{:3.1f} {:02d}.{:02d}"',
  '--parg=mqtt:home/bedroom/temperature',
  '--parg=time:hour',
  '--parg=time:min',
]

if node[ck].dig('config', 'homeassistant', 'activate')
  control_dir = '%t/%p/hass'
  control = ::File.join(control_dir, 'control')
  command << "--control=#{control}"
  command << '--off'
  control_setup.concat(
    [
      "mkdir --mode=750 #{control_dir}",
      "+chgrp homeassistant #{control_dir}",
      "ln -s #{control} %t/%p/led-bedroom",
    ],
  )
end

control_setup.concat(
  ['chgrp --reference=%t/%p', 'chmod 664'].map { |c| "+#{c} #{chown.map { |f| ::File.join(devdir, f) }.join(' ')}" },
)

test_service = {
  ExecStartPre: log_me,
  ExecStart: "sh -c ': #{name} i=%i I=%i f=%f; sleep 99d'",
}
normal_service = {
  WorkingDirectory: '/',
  RuntimeDirectory: '%p',
  RuntimeDirectoryMode: '755',
  ExecStart: (command + ['%i']).join(' '),
  ExecStartPre: log_me + control_setup,
  DynamicUser: true,
}
_extra_start = {
  DevicePolicy: 'closed',
  ProtectSystem: 'full',
  ProtectHome: true,
  ProtectKernelTunables: false,
  ProtectControlGroups: true,
  CapabilityBoundingSet: '',
  NoNewPrivileges: true,
  SystemCallFilter: '~@resources @privileged @obsolete @mount @clock @cpu-emulation @debug @keyring @module @raw-io',
  ProtectKernelModules: true,
  MemoryDenyWriteExecute: true,
  RestrictRealtime: true,
  SystemCallArchitectures: 'native',
  RestrictNamespaces: true,
  TimeoutStopSec: '3s',
}
service = activated ? normal_service : test_service

content = {
  Unit: {
    Description: 'Show time on Delcom 7 segment LED display',
  }.merge(unit),
  Service: service,
  Install: {
    # WantedBy: 'multi-user.target',
    # WantedBy: "#{systemd_alias.sub('/', '').gsub('/', '-')}.device",
  },
}
default[ck]['config']['systemd']['units']["#{name}@.service"]['content'] = activated ? content : {}

_debug_commands = <<~DEBUGCOMMANDS
  sudo udevadm  monitor --environment --udev
  udevadm info --attribute-walk /sys/bus/usb/drivers/usbsevseg/1*
  sudo udevadm test --action=add /sys/bus/usb/drivers/usbsevseg/1*
  See systemctl --all --full -t device to see a list of all decives for which systemd has a unit in your system.

  udevadm info  -x --name  /dev/bus/usb/001/014
  sudo udevadm test $(udevadm info --query=path --name  /dev/bus/usb/001/014)
  echo  1-1.1.3 | sudo tee /sys/bus/usb/drivers/usb/unbind
  echo  1-1.1.3 | sudo tee /sys/bus/usb/drivers/usb/bind
  journalctl -fp err

  systemctl status -t device --all

  This prints out rules that you can use to match the device in udev rules.
  The first block is about the device itself, and the subsequent blocks are about its ancestors in the device tree.
  The only caveat is that you cannot mix keys that correspond to different ancestors.
  udevadm info  -a --name  /dev/bus/usb/001/014
  https://unix.stackexchange.com/questions/124817/udev-how-do-i-find-out-which-subsystem-a-device-belongs-to
DEBUGCOMMANDS
