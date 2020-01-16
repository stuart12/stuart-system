return unless CfgHelper.activated? 'kooka'

package %w[
  wpasupplicant
] do
  action :remove
end

systemd_unit 'ssh' do
  action %i[disable stop]
end

user = CfgHelper.configure({ name: 'adb', home: '/srv/adb', group: 'plugdev' }, %w[adb user])

service = {
  ExecStart: '/usr/bin/adb start-server',
  Type: 'forking',
  User: user['name'],
  WorkingDirectory: user['home'],
  SupplementaryGroups: user['group'],
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

hass = 'homeassistant'

have_hass = 0.zero? # CfgHelper.activated?(hass)

user user['name'] do
  system true
  home user['home']
  manage_home true
  comment 'adb runner'
  action %i[create lock]
  only_if { have_hass }
end

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
