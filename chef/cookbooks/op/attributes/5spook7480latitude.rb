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
CfgHelper.activate 'npm'
CfgHelper.activate 'dotnet'
CfgHelper.activate 'postman'
CfgHelper.activate 'criteo'

CfgHelper.add_package 'firmware-iwlwifi'

CfgHelper.attributes(
  %w[networking],
  hostname: me,
  dhcp: true,
)

CfgHelper.override(
  %w[btrfs snapshot handler],
  hour: '7-19',
  minute: '*/15',
  volumes: %w[stuart s.pook] # FIXME: do all users?
    .map { |u| [u, "/home/#{u}"] }
    .to_h
    .merge(rootfs: '/')
    .merge('stuart-photos': '/home/stuart/photos')
    .map { |name, source| [name, source: source] }.to_h,
)

base = '/media/chef/Samsung500GBfs1'
root = ::File.join(base, 'default')
syncthing = ::File.join(root, 'Syncthing')
external = ::File.join(syncthing, 'mount')

CfgHelper.attributes(
  %w[syncthing mountpoints],
  '/dev/disk/by-label/Samsung500GBfs1': { 'default': root },
)

user = 'stuart'

CfgHelper.attributes(
  %w[syncthing users] + [user],
  rw: {
    'Syncthing/stuart' => 'Syncthing',
    'Syncthing/starlite-GPS-tracks' => 'starlite-GPS-tracks',
    'photos' => 'photos',
    'Syncthing/enchilada-photos' => 'enchilada-photos',
    'Syncthing/starlite-photos' => 'starlite-photos',
  } .transform_keys { |k| ::File.join(::Dir.home(user), k) }.merge(
    { ::File.dirname(external) => 'external' },
  ),
)

%w[
  blueman
  bluez-firmware
].each do |pkg|
  CfgHelper.add_package pkg
end

dft = {
  QHD: {
    config: {
      destination_directory: ::File.join('~', 'ws', 'converted-photos'),
      post_directory: ::File.join('~', 'ws', 'converted-photos-post'),
    },
    options: {
      quality: 95,
      width: 2560,
      height: 1440,
    },
    include: [
      'defaults.yaml', # yuck
    ],
  },
  config: {
    config: {
      destination_directory: ::File.join(root, 'stuart', 'converted-photos'),
      post_directory: ::File.join(external, 'stuart', 'converted-photos-post'),
    },
  },
}
CfgHelper.override(%w[photo_transforms configurations], dft)
