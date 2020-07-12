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
  options %w[noatime] + (CfgHelper.btrfs? ? %w[compress=zstd] : [])
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

bad_rawtherapee = { version: '5.8-*' } # https://github.com/Beep6581/RawTherapee/issues/5638
apt_prefs = CfgHelper.attributes(
  %w[apt preferences],
  rawtherapee: bad_rawtherapee,
  'rawtherapee-data': bad_rawtherapee,
)

template '/etc/apt/preferences.d/chef' do
  source 'apt.preferences.erb'
  variables(packages: apt_prefs)
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
    only_if { CfgHelper.btrfs? }
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
  create-alias
  dcim-read
  ring
  title-case
  windows10
].each do |name|
  pythonscript name
end

xsessiond = '/etc/X11/Xsession.d/10chef'
file xsessiond do
  content ['# Managed by Chef', '. /etc/profile'].map { |l| "#{l}\n" }.join
  only_if { ::File.directory?(::File.dirname(xsessiond)) }
  owner 'root'
  mode 0o644
end

pcmanfm = CfgHelper.attributes(
  %w[x11 lxde pcmanfm],
  config: {
    bm_open_method: 0,
    su_cmd: "xdg-su -c '%s'",
  },
  desktop: {
    wallpaper_mode: 'crop',
    wallpaper: '/etc/alternatives/desktop-background',
    desktop_bg: '#000000',
    desktop_fg: '#ffffff',
    desktop_shadow: '#000000',
  },
  ui: {
    always_show_tabs: 0,
    hide_close_btn: 0,
    win_width: 640,
    win_height: 480,
    view_mode: 'icon',
    show_hidden: 0,
    sort: 'name;ascending;',
  },
  volume: { # //www.raspberrypi.org/forums/viewtopic.php?t=91677
    mount_on_startup: 0,
    mount_removable: 0,
    autorun: 0,
  },
)

template '/etc/xdg/pcmanfm/LXDE/pcmanfm.conf' do
  source 'ini.erb'
  variables(
    sections: pcmanfm,
  )
  owner 'root'
  mode 0o644
end

etesync_users = CfgHelper.config(%w[etesync users]).select { |_, active| active }.keys
unless etesync_users.empty?
  etesync = 'etesync-dav@.service'

  override_dir = ::File.join('/etc/systemd/system', "#{etesync}.d")
  directory override_dir do
    owner 'root'
    mode 0o755
  end
  override_file = ::File.join(override_dir, 'override.conf')
  template override_file do
    source 'ini.erb'
    variables(
      comment: '#',
      sections: {
        Service:
          CfgHelper.config(%w[etesync environment])
          .reject { |_, v| v.nil? }
          .map { |n, v| ['Environment', "#{n}=#{v}"] }
          .concat(CfgHelper.config(%w[etesync service]).reject { |_, v| v.nil? }.to_a),
      },
    )
    owner 'root'
    mode 0o644
  end

  unit_file = ::File.join('/etc/systemd/system', etesync)
  file unit_file do
    content(lazy do
      [
        '# Managed by Chef',
        ::File.read(::File.join(CfgHelper.git_stuart('etesync-dav'), 'examples', 'systemd-sandbox', etesync)),
      ].join("\n")
    end)
    owner 'root'
    mode 0o644
    manage_symlink_source false
  end
  execute 'systemctl daemon-reload' do
    action :nothing
    subscribes :run, "file[#{unit_file}]", :delayed
    subscribes :run, "template[#{override_file}]", :delayed
  end
  etesync_users.each do |user|
    systemd_unit "etesync-dav@#{user}.service" do
      action :nothing
      subscribes :restart, "file[#{unit_file}]", :delayed
      subscribes :restart, "template[#{override_file}]", :delayed
      subscribes :start, "ruby_block[last #{user}]", :delayed
      subscribes :enable, "ruby_block[last #{user}]", :delayed
    end
    ruby_block "last #{user}" do
      block {}
    end
  end
end

qtpass = CfgHelper.attributes(
  %w[qtpass],
  config: {
    General: {
      autoclearPanelSeconds: 90,
      autoclearSeconds: 90,
      autoPull: true,
      autoPush: true,
      clipBoardType: 2,
      hideOnClose: true,
      hidePassword: true,
      passwordLength: 16,
      useAutoclear: true,
      useGit: true,
      useSelection: true,
      useTrayIcon: true,
    },
  },
  cfgfile: '/etc/xdg/IJHack/QtPass.conf',
)

directory ::File.dirname(qtpass['cfgfile']) do
  owner 'root'
  mode 0o755
end
template qtpass['cfgfile'] do
  variables(
    comment: ';',
    sections: qtpass['config'],
  )
  owner 'root'
  mode 0o644
  source 'ini.erb'
end

reconfigure = "dpkg-reconfigure #{node['os']}-image-#{node['os_version']}"
execute reconfigure do
  action :nothing
end
firmware = CfgHelper.config(%w[firmware]) || {}
(firmware['blobs'] || {}).select { |_, wanted| wanted }.keys.each do |blob|
  bin = "#{blob}.bin"
  remote_file ::File.join(firmware['destination'], bin) do
    source "#{firmware['url']}/#{bin}"
    owner 'root'
    mode 0o644
    notifies :run, "execute[#{reconfigure}]"
  end
end
