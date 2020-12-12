users = CfgHelper.config(%w[syncthing users])
return if users.empty?

paquet 'syncthing'

globals = CfgHelper.attributes(
  %w[syncthing overrides service],
  StateDirectoryMode: '0700',
  StateDirectory: '%N',
  Environment: 'HOME=%S/%N',

  RemoveIPC: true,
  PrivateTmp: true,
  ProtectSystem: 'strict',
  ProtectHome: true,
  PrivateDevices: true,
  PrivateUsers: true,
  ProtectKernelTunables: true,
  ProtectKernelModules: true,
  ProtectControlGroups: true,
  RestrictAddressFamilies: 'AF_UNIX AF_INET AF_INET6',
  RestrictNamespaces: true,
  NoNewPrivileges: true,

  LockPersonality: true,
  MemoryDenyWriteExecute: true,
  RestrictRealtime: true,
  SystemCallFilter: '@system-service',
  SystemCallErrorNumber: 'EPERM',
  SystemCallArchitectures: 'native',
  CapabilityBoundingSet: '',

  Nice: 4,
  MemoryHigh: '3G',
  IOAccounting: true,
  IPAccounting: true,
  TemporaryFileSystem: [
    '/snapshots', # FIXME: hack
    '/media',
  ].map { |n| "#{n}:ro" }.join(' '),
)

def bind_mappings(_user, cfg)
  cfg
    .select { |k, _| %w[ro rw].include? k }
    .transform_keys { |k| "Bind#{k == 'ro' ? 'ReadOnly' : ''}Paths" }
    .map do |op, v|
      v.map do |from, to|
        [op, "#{from}:#{::File.join('%S/%N/Sync', to)}"]
      end
    end
    .flatten(1)
end

users.each do |user, cfg|
  override_user = ::File.join('/etc/systemd/system', "syncthing@#{user}.service.d", 'override.conf')
  directory ::File.dirname(override_user) do
    owner 'root'
    mode 0o755
  end
  mappings = bind_mappings(user, cfg)
  template override_user do
    source 'ini.erb'
    variables(
      comment: '#',
      sections: {
        Service: mappings + globals.to_a,
      },
    )
    owner 'root'
    mode 0o644
  end
  execute 'systemctl daemon-reload' do
    action :nothing
    subscribes :run, "template[#{override_user}]", :immediately
  end
  systemd_unit "syncthing@#{user}.service" do
    action :nothing
    subscribes :restart, "template[#{override_user}]"
    subscribes :restart, 'paquet[syncthing]'
    subscribes :start, 'ruby_block[finish syncthing]'
    subscribes :enable, 'ruby_block[finish syncthing]'
  end
end

CfgHelper.config(%w[syncthing mountpoints]).each do |device, subvols|
  subvols.each do |subvol, mountpoint|
    directory mountpoint do
      owner 'root'
      recursive true
    end
    mount mountpoint do
      device device
      options "subvol=#{subvol},noauto,user"
      pass 0
      action :enable
    end
  end
end

ruby_block 'finish syncthing' do
  block {}
end
