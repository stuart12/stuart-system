return unless CfgHelper.activated? 'x11'

keyboard = CfgHelper.attributes(
  %w[x11 keyboard default],
  name: 'chef',
  suffix: '',
  default: {
    XKBLAYOUT: 'us+chef',
    XKBOPTIONS: 'ctrl:nocaps,lv3:win_switch',
    BACKSPACE: 'default',
  },
)

%w[types symbols].each do |which|
  dir = ::File.join('/usr/share/X11/xkb', which)
  file ::File.join(dir, 'stuart') do
    action :delete
  end
  template ::File.join(dir, keyboard['name']) do
    source "xkb_#{which}#{keyboard['suffix']}.erb"
    variables(name: keyboard['name'])
    owner 'root'
    mode 0o644
  end
end

reread = 'udevadm trigger --subsystem-match=input --action=change'

execute reread do
  action :nothing
end

template '/etc/default/keyboard' do
  variables(env: keyboard['default'])
  source 'etc_default.erb'
  owner 'root'
  mode 0o644
  notifies :run, "execute[#{reread}]"
end

execute 'update global dconf' do
  command 'dconf update'
  action :nothing
end

# https://help.gnome.org/admin/system-admin-guide/stable/dconf-lockdown.html.en
# https://unix.stackexchange.com/questions/49452/where-is-config-file-of-ibus-stored/236817#236817
# To see a users current values:
#   dconf dump /desktop/ibus/general/
# To check the values in the current database:
#   mkdir -p $TMP/dd/dconf
#   ln -s /etc/dconf/db/chef $TMP/dd/dconf/user
#   XDG_CONFIG_HOME=$TMP/dd dconf dump /desktop/ibus/general/

where = 'chef' # should this be 'user'?

template '/etc/dconf/profile/user' do
  source 'lines.erb'
  variables(lines: ['user-db:user', "system-db:#{where}"])
  owner 'root'
  mode 0o644
end

directory "/etc/dconf/db/#{where}.d" do
  owner 'root'
  mode 0o755
end

CfgHelper.attributes(
  %w[dconf],
  ibus: {
    'desktop/ibus/general': {
      'use-system-keyboard-layout': true,
    },
  },
).each do |name, cfg|
  template "/etc/dconf/db/#{where}.d/50-#{name}" do
    variables(
      comment: '#',
      sections: cfg,
    )
    source 'ini.erb'
    owner 'root'
    mode 0o644
    notifies :run, 'execute[update global dconf]'
  end
end

plugins = <<~PLUGIN
  Plugin {
    type=batt
    Config {
      BackgroundColor=black
      ChargingColor1=#28f200
      ChargingColor2=#22cc00
      DischargingColor1=#ffee00
      DischargingColor2=#d9ca00
      HideIfNoBattery=1
      AlarmCommand=notify-send "Battery low" --icon=battery-caution
      AlarmTime=5
      BorderWidth=1
      Size=8
      ShowExtendedInformation=1
    }
  }
PLUGIN
panel_dir = '/etc/xdg/lxpanel/LXDE/panels'
panel_default = ::File.join(panel_dir, 'panel')
panel =
  ::File
  .read(panel_default)
  .sub(
    /^\s*type = launchbar(\R)([[:blank:]]*)Config\s*{\R/,
    '\\0\\2\\2Button {\\1\\2\\2\\2id=lxterminal.desktop\\1\\2\\2}\\1',
  )

file ::File.join(panel_dir, 'chef-panel') do
  content "# Maintained by Chef\n#{panel}#{plugins}"
  owner 'root'
  mode 0o644
end

file panel_default do
  mode 0o600
end
