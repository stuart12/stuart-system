name = 'delcom-clock'
return unless CfgHelper.activated? name

i2c = CfgHelper.activated? 'i2c'
CfgHelper.my_repo(name)
CfgHelper.add_package 'python3-paho-mqtt' if i2c

systemd_alias = "/dev/alias/#{name.tr('-', '_')}/"

unit = {
  BindsTo: "#{systemd_alias.sub('/', '').tr('/', '-')}%i.device",
  DefaultDependencies: false,
  StopWhenUnneeded: true,
}

CfgHelper.set_config['udev']['rules'][name]['rules']['main'] = [
  'ACTION=="bind|unbind"',
  'ENV{PRODUCT}=="fc5/1227/*"',
  'ENV{DEVTYPE}=="usb_interface"',
  'TAG+="systemd"',
  "ENV{SYSTEMD_ALIAS}+=\"#{systemd_alias}%k\"",
  "ENV{SYSTEMD_WANTS}+=\"#{name}@$name.service\"",
  'PROGRAM="/usr/bin/logger -p notice %E{ACTION} delcom-clock name=$name k=%k n=%n p=%p b=%b driver=$driver N=%N"',
]

log_me = ["logger -p notice unit #{name} starting n=%n i=%i I=%I f=%f"]

chown = %w[../power/level powered mode_msb mode_lsb textmode text decimals]
devdir = '/sys/bus/usb/drivers/usbsevseg/%i'
control_setup = []

command = [
  ::File.join(CfgHelper.config['git-stuart']['root'], name, name),
  # '--verbose',
  '--loglevel=info',
]

if i2c
  command.concat(
    [
      '--update=60',
      '--pformat="{:3.1f} {:02d}.{:02d}"',
      '--parg=mqtt:home/bedroom/temperature',
      '--parg=time:hour',
      '--parg=time:min',
    ],
  )
end

if CfgHelper.activated? 'homeassistant'
  control_dir = '%t/%p/hass'
  control = ::File.join(control_dir, 'control')
  command << "--control=#{control}"
  command << '--off'
  command << '--mode=666'
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

command << '%i'

service = {
  WorkingDirectory: '/',
  RuntimeDirectory: '%p',
  RuntimeDirectoryMode: '755',
  ExecStart: command.join(' '),
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
CfgHelper.systemd_unit("#{name}@.service", content)

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
