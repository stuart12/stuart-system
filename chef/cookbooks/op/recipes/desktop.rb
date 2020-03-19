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
  lightdm
  lxde
  ruby-shadow
  strace
  sudo
  unison
] do
  action :upgrade
end

sudo 'stuart' do
  user 'stuart'
end

systemd_unit 'lightdm' do
  action :start
end

home = '/home'

(CfgHelper.config['users']['real'] || {}).each do |user, cfg|
  next unless cfg['name']
  execute "btrfs subvol create #{user}" do
    cwd home
    creates ::File.join(home, user)
  end
  user user do
    comment cfg['name']
    password cfg['password'] || raise("no password configured for #{user}")
  end
end

template '/etc/gitconfig' do
  source 'ini.erb'
  variables(
    sections: {
      user: {
        email: 'stuart12@users.noreply.github.com',
        name: 'Stuart Pook',
      },
    },
  )
  mode 0o644
  user 'root'
end
