# maintained by Chef
[Service]

DynamicUser=yes
SupplementaryGroups=audio
ExecStart=
ExecStart=/usr/bin/snapclient --hostID %H --soundcard hw:CARD=DAC
Nice=-5
RuntimeDirectory=%N

ProtectSystem=strict
DeviceAllow=char-alsa rw
PrivateUsers=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
RestrictNamespaces=true
NoNewPrivileges=true
MemoryDenyWriteExecute=true
RestrictRealtime=true
# https://github.com/systemd/systemd/commit/ee8f26180d01e3ddd4e5f20b03b81e5e737657ae not in v232
#SystemCallFilter=~@clock @cpu-emulation @debug @keyring @module @mount @obsolete @raw-io
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM
SystemCallArchitectures=native
CapabilityBoundingSet=
