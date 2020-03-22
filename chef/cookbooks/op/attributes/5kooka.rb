return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '315c4bf7-9da3-4377-8c63-1d4005fce534'

CfgHelper.attributes(
  %w[networking],
  hostname: 'kooka',
  interface: 'eno1',
)

CfgHelper.activate 'delcom-clock'
CfgHelper.activate 'desktop'
CfgHelper.activate 'kooka'
