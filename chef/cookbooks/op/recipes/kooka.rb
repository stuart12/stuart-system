return unless CfgHelper.activated? 'kooka'

include_recipe '::snapserver'

package %w[
  wpasupplicant
] do
  action :remove
end

systemd_unit 'ssh' do
  action %i[disable stop]
end
file '/etc/ssh/sshd_config.d/stuart.conf' do
  content [
    '# Managed by chef',
    'AllowUsers stuart',
    'PasswordAuthentication no',
  ].map { |v| "#{v}\n" }.join
  mode 0o644
  owner 'root'
end

service = {
  ExecStart: '/usr/bin/adb start-server',
  Type: 'forking',
  DynamicUser: true, # http://0pointer.net/blog/dynamic-users-with-systemd.html
  StateDirectory: '%N',
  WorkingDirectory: '%S/%N',
  Environment: 'HOME=%S/%N',
  SupplementaryGroups: CfgHelper.configure('plugdev', %w[adb group]),
  ProtectSystem: 'full',
  NoNewPrivileges: true,
  PrivateTmp: true,
  RestrictRealtime: true,
  SystemCallArchitectures: 'native',
  ProtectHome: true,
  ProtectKernelTunables: false,
  ProtectControlGroups: true,
  ProtectKernelModules: true,
  RestrictNamespaces: true,
  CapabilityBoundingSet: '',
  SystemCallFilter: '~@resources @privileged @obsolete @mount @clock @cpu-emulation @debug @keyring @module @raw-io',
  MemoryDenyWriteExecute: true,
  # DevicePolicy: 'closed',
}

have_hass = 0.zero? # CfgHelper.activated?(hass)

package 'adb' do
  only_if { have_hass }
end

hass = 'homeassistant'

content = {
  Unit: {
    Description: "Run adb for #{hass}",
    Before: "#{hass}.service",
  },
  Service: service,
  Install: {
    WantedBy: "#{hass}.service",
  },
}

CfgHelper.configure({ adb: content }, %w[adb systemd]).transform_keys { |k| "#{k}.service" }.each do |name, cfg|
  systemd_unit name do
    content cfg
    action %i[create enable]
    notifies :restart, "systemd_unit[#{name}]", :delayed
    only_if { have_hass }
  end
end
