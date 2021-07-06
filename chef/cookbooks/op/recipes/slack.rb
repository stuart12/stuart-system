return unless CfgHelper.activated? 'slack'

cfg = CfgHelper.attributes(
  ['slack'],
  url: 'https://downloads.slack-edge.com/linux_releases/slack-desktop-4.17.0-amd64.deb',
  hide: '/usr/lib/slack',
  delete: '/etc/cron.daily/slack',
  checksum: 'b1e7123f9e51d292b647fecd42236f2de3b3f863c631e8278d47e08b8aae8c1d',
)
remote_deb 'slack' do
  url cfg['url']
  hide cfg['hide']
  delete cfg['delete']
  checksum cfg['checksum']
end
