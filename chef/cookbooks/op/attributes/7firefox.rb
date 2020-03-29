return unless CfgHelper.activated? 'firefox'

CfgHelper.attributes(
  %w[mime defaults],
  'Default Applications': {
    'x-scheme-handler/http': 'firefox.desktop',
    'x-scheme-handler/https': 'firefox.desktop',
  },
)
