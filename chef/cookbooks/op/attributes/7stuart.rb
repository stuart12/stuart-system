return unless CfgHelper.activated? 'stuart'

CfgHelper.attributes(
  %w[firefox preferences],
  'identity.sync.tokenserver.uri' => {
    value: 'https://mozillasync.pook.it/token/1.0/sync/1.5',
    priority: 'pref',
  },
)
