return unless CfgHelper.activated? 'desktop'

root = node['filesystem']['by_mountpoint']['/']

mount '/' do
  action :disable
  device root['devices'].first
  only_if { root['devices'].length == 1 }
  only_if { root['devices'].first.start_with?('/dev/mapper/') }
end

mount '/' do
  device root['uuid']
  device_type :uuid
  fstype root['fs_type']
  options %w[noatime compress=zstd] # FIXME: if not btrfs?
  action :enable
  enabled true
  dump 0
  pass 0
end

apt_repository 'sid' do
  uri 'http://deb.debian.org/debian/'
  components %w[main contrib]
  distribution 'sid'
  deb_src true
end

package %w[
  unattended-upgrades
] do
  action :remove
end

template '/etc/apt/preferences.d/chef' do
  source 'apt.preferences.erb'
  variables(packages: { unison: {} })
end

package %w[
  btrfs-progs
  chromium
  evince
  firefox
  geeqie
  gimp
  lightdm
  lxde
  memtest86+
  qemu-system-x86-64
  rawtherapee
  ruby-shadow
  strace
  sudo
  syncthing
  thunderbird
  unison
] do
  action :upgrade
end

sudo 'stuart' do
  user 'stuart'
  defaults %w[rootpw timestamp_timeout=7302 !tty_tickets]
end

systemd_unit 'lightdm' do
  action :start
end

homes = '/home'

(CfgHelper.config['users']['real'] || {}).each do |user, cfg|
  next unless cfg['name']
  home = ::File.join(homes, user)
  execute "btrfs subvol create #{user}" do
    cwd homes
    creates ::File.join(homes, user)
  end
  user user do
    comment cfg['name']
    password cfg['password'] || raise("no password configured for #{user}")
    shell '/bin/bash'
  end
  directory home do
    user user
    group user
    mode 0o700
  end
end

group 'work' do
  members 's.pook'
  comment 'access to work programs'
end

extensions = '/usr/lib/firefox/distribution/extensions'
directory extensions do
  owner 'root'
  mode 0o755
end

# to find the ID see extensions.webextensions.uuid in about:config
{
  '@contain-facebook' => 3_519_841,
  'forget-me-not@lusito.info' => 3_468_924,
  'https-everywhere@eff.org' => 3_442_258,
  'addon@darkreader.org' => 3_528_805,
}.each do |id, url|
  remote_file ::File.join(extensions, "#{id}.xpi") do
    source "https://addons.mozilla.org/firefox/downloads/file/#{url}/"
    owner 'root'
    mode 0o644
  end
end
