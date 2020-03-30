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
