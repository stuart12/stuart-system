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
