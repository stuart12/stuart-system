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

%w[unstable testing stable].each do |distrib|
  apt_repository distrib do
    uri 'http://deb.debian.org/debian/'
    components %w[main contrib]
    distribution distrib
    deb_src true
  end
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
  apt-file
  btrfs-progs
  chromium
  dnsutils
  evince
  firefox
  geeqie
  gimp
  lightdm
  linux-image-amd64
  lxde
  memtest86+
  qemu-system-x86-64
  qtqr
  rawtherapee
  rename
  ruby-shadow
  strace
  sudo
  syncthing
  thunderbird
  unison
  zbar-tools
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

users = CfgHelper.config['users']['users'] || {}
users.each do |user, cfg|
  next unless cfg['name']
  home = ::File.join(homes, user)
  create = 'btrfs subvolume create'
  mkcache = "#{create} for #{user}"
  execute mkcache do
    command %w[.cache tmp].map { |w| "#{create} #{w} && chown #{user}:#{user} #{w} && chmod 700 #{w}" }.join(' && ')
    action :nothing
    cwd home
  end
  execute "#{create} #{home}" do
    creates home
    notifies :run, "execute[#{mkcache}]", :delayed
  end
  user user do
    comment cfg['name']
    password cfg['password'] || raise("no password configured for #{user}")
    shell '/bin/bash'
    action :create
  end
  directory home do
    user user
    group user
    mode 0o700
  end
end
users.map { |user, cfg| [user, cfg['groups'] || []] }
     .flat_map { |user, groups| groups.map { |g| [g, user] } }
     .group_by(&:first)
     .transform_values { |v| v.map(&:last) }
     .each do |group, members|
  group group do
    members members
  end
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

template '/etc/ssh/ssh_config.d/chef.conf' do
  source 'ssh_config.erb'
  variables(
    hosts: {
      'github.com' => {
        IdentitiesOnly: 'yes',
        IdentityFile: '~/.ssh/github',
      },
    },
  )
  owner 'root'
  mode 0o644
end

template '/usr/share/lxterminal/lxterminal.conf' do
  # To get this file to be read again remove /home/*/.config/lxterminal/lxterminal.conf
  source 'ini.erb'
  variables(
    sections: {
      general: {
        fontname: 'Monospace 11',
        selchars: '-A-Za-z0-9,./?%&#:_',
        scrollback: 1013,
        bgcolor: 'rgb(0,0,0)',
        fgcolor: 'rgb(211,215,207)',
        palette_color_0: 'rgb(0,0,0)',
        palette_color_1: 'rgb(205,0,0)',
        palette_color_2: 'rgb(78,154,6)',
        palette_color_3: 'rgb(196,160,0)',
        palette_color_4: 'rgb(52,101,164)',
        palette_color_5: 'rgb(117,80,123)',
        palette_color_6: 'rgb(6,152,154)',
        palette_color_7: 'rgb(211,215,207)',
        palette_color_8: 'rgb(85,87,83)',
        palette_color_9: 'rgb(239,41,41)',
        palette_color_10: 'rgb(138,226,52)',
        palette_color_11: 'rgb(252,233,79)',
        palette_color_12: 'rgb(114,159,207)',
        palette_color_13: 'rgb(173,127,168)',
        palette_color_14: 'rgb(52,226,226)',
        palette_color_15: 'rgb(238,238,236)',
        color_preset: 'Tango',
      },
    },
  )
  owner 'root'
  mode 0o644
end

%w[
  criteo-connect
  title-case
].each do |name|
  link ::File.join('/usr/local/bin', name) do
    to ::File.join(CfgHelper.config['git-stuart']['root'], 'python-scripts', name)
  end
end

package %w[
  firefox-esr
] do
  action :remove
end
