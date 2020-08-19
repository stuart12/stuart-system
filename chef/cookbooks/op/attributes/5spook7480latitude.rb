me = 'spook-7480latitude'

CfgHelper.attributes(%w[networking hosts], me => 3)

return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '9598eec9-7ec3-4b0f-b731-f5ee47716a3e'

CfgHelper.activate 'desktop'
CfgHelper.activate 'sshd'
CfgHelper.activate 'gradle'
CfgHelper.activate 'intellij_idea'
CfgHelper.activate 'swap'
CfgHelper.activate 'zoom'
CfgHelper.activate 'slack'
CfgHelper.activate 'bluejeans'
CfgHelper.activate 'stuart'
CfgHelper.activate 'abank'
CfgHelper.activate 'sane'
CfgHelper.activate 'wifi'
CfgHelper.activate 'photo_transforms'

CfgHelper.add_package 'firmware-iwlwifi'

CfgHelper.attributes(
  %w[networking],
  hostname: me,
  dhcp: true,
)

CfgHelper.override(
  %w[btrfs snapshot handler],
  hour: '9-19',
  minute: '*/15',
  volumes: %w[stuart s.pook] # FIXME: do all users?
    .map { |u| [u, "/home/#{u}"] }
    .to_h
    .merge(rootfs: '/')
    .merge('stuart-photos': '/home/stuart/photos')
    .map { |name, source| [name, source: source] }.to_h,
)

CfgHelper.attributes(
  %w[syncthing users stuart],
  rw: {
    'Syncthing' => 'Syncthing',
    'photos' => 'photos',
    'Books' => 'books',
  },
)
