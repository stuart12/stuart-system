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

components = %w[main contrib non-free]
%w[unstable testing stable].each do |distrib|
  apt_repository distrib do
    uri 'http://deb.debian.org/debian/'
    components components
    distribution distrib
    deb_src true
  end
end
apt_repository 'security' do
  uri 'http://security.debian.org/debian-security/'
  components components
  distribution 'stable/updates'
  deb_src true
end
file '/etc/apt/sources.list' do
  action :delete
end

package %w[
  clipit
  unattended-upgrades
  xscreensaver
] do
  action :remove
end

template '/etc/apt/preferences.d/chef' do
  source 'apt.preferences.erb'
  variables(packages: {})
end

systemd_unit 'lightdm' do
  action :start
end

CfgHelper.users.each do |user, cfg|
  sudo user do
    user user
    defaults %w[rootpw timestamp_timeout=7302 !tty_tickets]
    action cfg['sudo'] ? :create : :delete
  end

  home = ::File.join('/home', user)
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
    only_if { root['fs_type'] == 'btrfs' }
  end
  user user do
    comment cfg['name']
    password CfgHelper.secrets['users'][user]['password'] || raise("no password for #{user}")
    shell '/bin/bash'
    action :create
  end
  directory home do
    user user
    group user
    mode 0o700
  end
end

user_groups = CfgHelper.users.map do |user, cfg|
  [user, (cfg['groups'] || []) + (cfg['work'] ? [CfgHelper.config['work']['group']] : [])]
end

def swap_keys_values(hash)
  hash
    .flat_map { |oldkey, newkeys| newkeys.map { |newkey| [newkey, oldkey] } }
    .group_by(&:first) # group by the new key
    .transform_values { |v| v.map(&:last) } # remove the new key from the value
end
swap_keys_values(user_groups).each do |group, members|
  group group do
    members members
  end
end

template '/usr/share/lxterminal/lxterminal.conf' do
  # To get this file to be read again remove /home/*/.config/lxterminal/lxterminal.conf
  source 'ini.erb'
  variables(
    sections: {
      general: {
        fontname: 'Monospace 11',
        selchars: '-A-Za-z0-9,./?%&#:_',
        scrollback: 10_264,
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
  title-case
].each do |name|
  link ::File.join('/usr/local/bin', name) do
    to ::File.join(CfgHelper.git_stuart('python-scripts'), name)
  end
end
file ::File.join('/usr/local/bin', 'criteo-connect') do
  action :delete # FIXME: remove
end

xsessiond = '/etc/X11/Xsession.d/10chef'
file xsessiond do
  content ['# Managed by Chef', '. /etc/profile'].map { |l| "#{l}\n" }.join
  only_if { ::File.directory?(::File.dirname(xsessiond)) }
  owner 'root'
  mode 0o644
end
