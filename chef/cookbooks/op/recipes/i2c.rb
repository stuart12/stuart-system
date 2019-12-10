ck = 'stuart'

i2c = node[ck]['config']['i2c']['activate']

%w[i2c-tools python3-paho-mqtt python3-rpi.gpio].each do |pkg|
  package pkg do
    action i2c ? :upgrade : :remove
  end
end

package 'python3-pip' do
  action i2c ? :upgrade : :nothing
end

modules = ['i2c_dev']
template '/etc/modules-load.d/chef.conf' do
  source 'modules-load.d.erb'
  variables(
    modules: modules,
  )
  user 'root'
  mode 0o644
  action i2c ? :create : :delete
end

modules.each do |module_name|
  # use kernel_module resource in Chef 14.3
  execute "modprobe #{module_name}" do
    only_if { i2c }
    only_if { File.foreach('/proc/modules').grep(/^#{module_name}\W/).empty? }
  end
end

# https://docs.chef.io/resource_systemd_unit.html
# rubocop:disable Metrics/BlockLength
{ 'home/bedroom/temperature' => 0x19, 'home/pi/temperature' => 0x1a }.each do |topic, address|
  scripts = ::File.join(node[ck]['config']['git']['directory'], 'github.com/stuart12', 'python-scripts')
  systemd_unit "mcp9809mqtt-#{address.to_s(16)}.service" do
    action i2c ? %w[create enable start] : %w[stop delete]
    content(
      Unit: {
        Description: 'Start mcp9809mqtt to publish temperatures from a MCP9808 to MQTT',
        Documentation: 'https://learn.adafruit.com/adafruit-mcp9808-precision-i2c-temperature-sensor-guide/python-circuitpython',
        After: 'network-online.target',
      },
      Service: {
        UMask: '022',
        RuntimeDirectory: '%N',
        RuntimeDirectoryMode: '0700',
        WorkingDirectory: '%t/%N',
        Environment: 'HOME=%t/%N',
        ExecStartPre: '/usr/bin/pip3 --no-cache-dir install adafruit-circuitpython-mcp9808',
        ExecStart: "#{scripts}/mcp9809mqtt --topic #{topic} --address 0x#{address.to_s(16)} --loglevel debug",
        DynamicUser: 'true',
        Group: 'i2c',
        DeviceAllow: 'char-i2c rw',
        DevicePolicy: 'closed',
        CapabilityBoundingSet: '',
        NoNewPrivileges: 'true',
        PrivateUsers: 'true',
        ProtectControlGroups: 'true',
        ProtectHome: 'true',
        ProtectKernelModules: 'true',
        ProtectKernelTunables: 'true',
        RestrictAddressFamilies: 'AF_UNIX AF_INET AF_INET6',
        RestrictRealtime: 'true',
        MemoryDenyWriteExecute: 'true',
        # SystemCallFilter: '@system-service',
        TemporaryFileSystem: '/var:ro /docker:ro /media:ro',
        InaccessiblePaths: '/mnt /boot',
        MemoryHigh: '512M',
        CPUQuota: '8%',
        TasksMax: 6.to_s,
      },
      Install: {
        WantedBy: 'multi-user.target',
      },
    )
  end
end
# rubocop:enable Metrics/BlockLength
