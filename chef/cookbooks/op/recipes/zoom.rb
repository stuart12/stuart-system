return unless CfgHelper.activated? 'zoom'

# https://zoom.us/
# cloud platform for video and audio conferencing, collaboration, chat, and webinars

cfg = CfgHelper.attributes(
  %w[external zoom],
  url: 'https://zoom.us/client/latest/zoom_amd64.deb',
  checksum: '11d4b67ad12a04812c6a4b2ac5384f3c5232d0e881ca6b01cb261cf795f7a29f',
  postinst: 'update-desktop-database',
  options: ['--no-triggers', '--post-invoke=update-desktop-database'],
  group: 'work',
  mode: 0o754,
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

cfg['dependencies'].each do |pkg|
  paquet pkg
end

deb = ::File.join(Chef::Config[:file_cache_path], 'zoom.deb')

remote_file deb do
  source cfg['url']
  checksum checksum
  owner 'root'
  mode 0o644
  notifies :remove, 'dpkg_package[zoom]', :immediately
end

dpkg_package 'zoom' do
  source deb
  options cfg['options']
end

directory "chgrp #{cfg['install']} to #{cfg['group']}/#{cfg['mode']}" do
  path cfg['install']
  mode cfg['mode']
  owner 'root'
  group cfg['group']
  not_if { !cfg['install'] }
end

template cfg['global']['file'] do
  source 'ini.erb'
  variables sections: cfg['global']['defaults']
  owner 'root'
  mode 0o644
end
