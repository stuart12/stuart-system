ck = 'stuart'
name = 'snapclient'
activated = node[ck].dig('config', name, 'activate')
default[ck]['config']['packages']['install']['snapclient'] = true if activated

unit = {
  Description: 'Snapcast client',
  Documentation: 'man:snapclient(1)',
  Wants: 'avahi-daemon.service',
  After: 'network.target time-sync.target sound.target avahi-daemon.service',
}

service = {
  DynamicUser: true,
  SupplementaryGroups: 'audio',
  ExecStart: "/usr/bin/snapclient --hostID #{node.name}",
  Nice: -5,
  RuntimeDirectory: '%N',
  StandardOutput: 'null', # very noisy on stdout
  Restart: 'on-failure',

  ProtectSystem: 'strict',
  DeviceAllow: 'char-alsa rw',
  PrivateUsers: true,
  ProtectKernelTunables: true,
  ProtectKernelModules: true,
  ProtectControlGroups: true,
  RestrictAddressFamilies: 'AF_UNIX AF_INET AF_INET6 AF_NETLINK',
  RestrictNamespaces: true,
  NoNewPrivileges: true,
  MemoryDenyWriteExecute: true,
  RestrictRealtime: true,
  SystemCallFilter: '@system-service',
  SystemCallErrorNumber: 'EPERM',
  SystemCallArchitectures: 'native',
  CapabilityBoundingSet: '',
}

install = {
  WantedBy: 'multi-user.target',
}

content = {
  Unit: unit,
  Service: service,
  Install: install,
}

default[ck]['config']['systemd']['units']["#{name}@.service"]['content'] = activated ? content : {}
