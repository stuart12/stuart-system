return unless CfgHelper.activated? 'slack'

cfg = CfgHelper.attributes(
  ['slack'],
  url: 'https://downloads.slack-edge.com/linux_releases/slack-desktop-4.4.0-amd64.deb',
  hide: '/usr/lib/slack',
  delete: '/etc/cron.daily/slack',
  checksum: '22dc90c14a845b9d789952d2c97d76bd54a350062a6d8d9b51097b91fa735940',
)
remote_deb 'slack' do
  url cfg['url']
  hide cfg['hide']
  delete cfg['delete']
  checksum cfg['checksum']
end
