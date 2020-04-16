return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '9598eec9-7ec3-4b0f-b731-f5ee47716a3e'

CfgHelper.activate 'desktop'
CfgHelper.activate 'sshd'
CfgHelper.activate 'gradle'
CfgHelper.activate 'intellij_idea'
CfgHelper.activate 'swap'
CfgHelper.activate 'zoom'
CfgHelper.activate 'slack'
CfgHelper.activate 'stuart'

CfgHelper.add_package 'firmware-iwlwifi'

CfgHelper.attributes(
  %w[networking],
  hostname: 'spook-7480latitude',
  dhcp: true,
)
