return unless CfgHelper.activated? 'zoom'

# https://zoom.us/
# cloud platform for video and audio conferencing, collaboration, chat, and webinars

if 1.zero?
  CfgHelper.override(
    %w[external zoom],
    url: 'https://ota.zoom.us/Linux/64bit/zoom_withlog_latest_amd64.deb',
    checksum: '7bfe38922aa9de76a725880cddc2c48fa6d109279d36c4c20a6f8b051f22ebe7',
  )
end

cfg = CfgHelper.attributes(
  %w[external zoom],
  url: 'https://zoom.us/client/latest/zoom_amd64.deb',
  checksum: '11d4b67ad12a04812c6a4b2ac5384f3c5232d0e881ca6b01cb261cf795f7a29f',
  options: '--post-invoke=update-desktop-database',
  install: '/opt/zoom',
  global: {
    file: '/etc/xdg/zoomus.conf',
    defaults: {
      General: {
        embeddedBrowserForSSOLogin: false,
      },
    },
  },
  dependencies: %w[
    libgl1-mesa-glx
    libegl1-mesa
    libxcb-xtest0
    ibus
  ],
)

remote_deb 'zoom' do
  url cfg['url']
  hide cfg['install']
  checksum cfg['checksum']
  options cfg['options']
  dependencies cfg['dependencies']
end

template cfg['global']['file'] do
  source 'ini.erb'
  variables sections: cfg['global']['defaults']
  owner 'root'
  mode 0o644
end
