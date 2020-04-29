return unless CfgHelper.btrfs?

CfgHelper.attributes(
  %w[btrfs subvolumes convert],
  '/var/tmp' => true,
  '/var/cache' => true,
).select { |_, wanted| wanted }.keys.each do |dir|
  old = "#{dir}.chef-old"
  stat = ::File::Stat.new(dir)

  log 'reboot' do
    message "reboot as #{dir} replaced"
    action :nothing
    level :fatal
  end

  copy_attributes = "copy attributes from #{old} to #{dir}"
  ruby_block copy_attributes do
    block do
      ::File.chown(stat.uid, stat.gid, dir)
      ::File.chmod(stat.mode, dir)
    end
    action :nothing
    notifies :write, 'log[reboot]', :delayed
  end

  create = "btrfs subvolume create #{dir}"
  execute create do
    action :nothing
    notifies :run, "ruby_block[#{copy_attributes}]", :immediate
  end

  ruby_block "rename #{dir} to #{old}" do
    block do
      ::File.rename(dir, old)
    end
    only_if { stat.dev == ::File::Stat.new(::File.dirname(dir)).dev }
    notifies :run, "execute[#{create}]", :immediate
  end
end

cfg = CfgHelper.attributes(
  %w[btrfs snapshot handler],
  cfgfile: '/etc/cheffise/snapshots',
  hour: 8,
  days: 10,
  minute: 55,
  second: 0,
  destination: '/snapshots',
)

snapshot_cfg_file = cfg['cfgfile']
volumes = cfg['volumes'] || {}
destination = cfg.dig('destination')
execute "btrfs subvolume create #{destination}" do
  creates destination
  not_if { volumes.empty? }
end
directory ::File.dirname(snapshot_cfg_file) do
  owner 'root'
  mode 0o755
end
template snapshot_cfg_file do
  source 'ini.erb'
  variables(
    comment: '#',
    sections: volumes.merge(
      DEFAULT: (volumes['DEFAULT'] || {}). merge(DestinationDirectory: destination, days: cfg['days']),
    ),
  )
  mode 0o644
  owner 'root'
end
cron_d 'snapshot-handler' do
  command "btrfs-snapshot-handler.py --config #{snapshot_cfg_file}"
  path "#{CfgHelper.git_stuart('python-scripts')}:/bin:/sbin"
  hour cfg['hour']
  minute cfg['minute']
  not_if { volumes.empty? }
end
%w[python3-tz python3-dateutil].each do |pkg|
  paquet pkg do
    not_if { volumes.empty? }
  end
end
