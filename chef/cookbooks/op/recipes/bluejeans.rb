return unless CfgHelper.activated? 'bluejeans'

# https://www.bluejeans.com/downloads
# cloud platform for video and audio conferencing, collaboration, chat, and webinars

cfg = CfgHelper.attributes(
  %w[external bluejeans],
  url: 'https://swdl.bluejeans.com/desktop-app/linux/2.1.2/BlueJeans.deb',
  options: [
    'gtk-update-icon-cache /usr/share/icons/hicolor/',
    'update-desktop-database',
  ].map { |cmd| "--post-invoke=#{cmd}" },
  install: '/opt/BlueJeans',
  dependencies: %w[
    gconf2
    libnss3
    libappindicator1
  ],
)

remote_deb 'bluejeans' do
  url cfg['url']
  hide cfg['install']
  checksum cfg['checksum'] if cfg['checksum']
  options cfg['options']
  dependencies cfg['dependencies']
  group 'bluejeans'
end
