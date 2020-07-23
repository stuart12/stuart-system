return unless CfgHelper.activated? 'etesync_dav'

etesync_users = CfgHelper.config(%w[etesync users]).select { |_, active| active }.keys

return if etesync_users.empty?

cfg = CfgHelper.attributes(
  %w[etesync],
  branch: 'update-for-0.16.0+245',
)

repo = 'etesync-dav'
git_clone = CfgHelper.git_stuart(repo)
git git_clone do # should be a resource
  repository ::File.join('https://', 'github.com', 'stuart12', repo)
  revision cfg['branch']
  user 'root'
end

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
      ::File.read(::File.join(git_clone, 'examples', 'systemd-sandbox', etesync)),
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
    subscribes :restart, "git[#{git_clone}]", :delayed
    subscribes :start, "ruby_block[last #{user}]", :delayed
    subscribes :enable, "ruby_block[last #{user}]", :delayed
  end
  ruby_block "last #{user}" do
    block {}
  end
end
