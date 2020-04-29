me = 'kooka'

CfgHelper.attributes(%w[networking hosts], me => 8)

return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '315c4bf7-9da3-4377-8c63-1d4005fce534'

CfgHelper.attributes(
  %w[networking],
  hostname: me,
  interface: 'eno1',
)

CfgHelper.activate %w[
  delcom-clock
  desktop
  kooka
  stuart
  homeassistant
  hass_main
]

CfgHelper.attributes(
  %w[ssh hosts],
  {
    my_laptop: {
      Host: ['spook-7480latitude'],
      ControlMaster: 'auto',
      ControlPath: '~/.ssh/control-%C',
      IdentityFile: '~/.ssh/restricted/id_rsa',
    },
  }.merge(
    { bathroom: 11_123, entrance: 9123, bedroom: 10_123 } .transform_values do |port|
      {
        LocalForward: [port, 'localhost:8123'],
        ControlMaster: 'auto',
        ControlPath: '~/.ssh/control-%C',
        ForwardAgent: 'yes',
        IdentityFile: '~/.ssh/restricted/id_rsa',
        User: 'pi',
      }
    end,
  ),
)

CfgHelper.override(
  %w[btrfs snapshot handler],
  destination: '/disks/snapshots',
  days: 40,
  volumes: {
    rootfs: '/',
    'stuart-home': '/home/stuart',
    'stuart-archive': '/home/stuart/archive',
    music: '/disks/music',
  }.map { |name, source| [name, source: source] }.to_h.merge(
    photos: {
      source: '/home/stuart/photos',
      days: 386,
    },
  ),
)
