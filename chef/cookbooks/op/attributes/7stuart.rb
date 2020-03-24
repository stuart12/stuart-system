return unless CfgHelper.activated? 'stuart'

CfgHelper.attributes(
  %w[firefox preferences],
  'identity.sync.tokenserver.uri' => {
    value: 'https://mozillasync.pook.it/token/1.0/sync/1.5',
    priority: 'pref',
  },
)

CfgHelper.attributes(
  %w[ssh hosts],
  fix: {
    IdentitiesOnly: 'yes',
    HostName: 'fr-criteo-spook.criteois.lan',
    IdentityFile: '%d/.ssh/fix',
    User: 's.pook',
    ForwardAgent: 'yes',
    DynamicForward: 23_151,
    ControlMaster: 'auto',
    ControlPath: '~/.ssh/control-%C',
  },
  'email-aliases': {
    IdentityFile: '%d/.ssh/hh',
    User: 'editor',
    Port: 2223,
    HostName: 'hh.pook.it',
  },
  hh: {
    User: 'core',
    HostName: 'hh.pook.it',
    IdentitiesOnly: 'yes',
    ForwardAgent: 'yes',
    ControlMaster: 'auto',
    ControlPath: '~/.ssh/control-%C',
    IdentityFile: '%d/.ssh/hh',
  },
)
