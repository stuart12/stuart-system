ck = 'stuart'
activated = node[ck].dig('config', 'delcom-clock', 'activate')
name = 'delcom-clock'

%w[python3-paho-mqtt].each do |pkg|
  package pkg do
    action activated ? :upgrade : :nothing
  end
end

gitdir = ::File.join(node[ck]['config']['git']['directory'], 'github.com', 'stuart12')
directory gitdir do
  recursive true
  user 'root'
  mode 0o755
end
repo = ::File.join('https://github.com/stuart12', name)
git ::File.join(gitdir, name) do
  repository repo
  revision 'master'
  user 'root'
end

command = [
  ::File.join(gitdir, name, name),
  # '--verbose',
  '--mode=666',
  '--update=60',
  '--pformat="{:3.1f} {:02d}.{:02d}"',
  '--parg=mqtt:home/bedroom/temperature',
  '--parg=time:hour',
  '--parg=time:min',
]

control_setup = if node[ck].dig('config', 'homeassistant', 'activate')
                  control_dir = '%t/%p/hass'
                  control = ::File.join(control_dir, 'control')
                  command << "--control=#{control}"
                  command << '--off'
                  [
                    "mkdir --mode=750 #{control_dir}",
                    "+chgrp homeassistant #{control_dir}",
                    "ln -s #{control} %t/%p/led-bedroom",
                  ]
                else
                  []
                end

chown = '../power/level powered mode_msb mode_lsb textmode text decimals'
unit_service = {
  WorkingDirectory: '/sys/bus/usb/drivers/usbsevseg/%i',
  RuntimeDirectory: '%p',
  RuntimeDirectoryMode: '755',
  ExecStart: (command + ['%i']).join(' '),
  ExecStartPre: control_setup + ['chgrp --reference=%t/%p', 'chmod 664'].map { |c| "+#{c} #{chown}" },
  DynamicUser: true,
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

[].map { |v| ::File.join('/etc/udev/rules.d', "#{v}.rules") }.each do |fn|
  template fn do
    user 'root'
    mode 0o644
    variables(group: group)
    action activated ? :create : :delete
  end
end

requires = %w[mosquitto.service]
systemd_unit "#{name}@.service" do
  action activated ? :create : :delete
  content(
    Unit: {
      Description: 'Show time and date on Delcom 7 segment LED display',
      Documentation: repo,
      After: requires,
      Requires: requires,
    },
    Service: unit_service,
    Install: {
      WantedBy: 'multi-user.target',
    },
  )
  subscribes :restart, 'file[/etc/timezone]'
  subscribes :restart, 'link[/etc/localtime]'
end
