ck = node['stuart']

return unless ck.dig('config', 'sshd', 'activate')

root = '/etc/ssh'
keysdir = ::File.join(root, 'authorized_keys')

keys = ck.dig('config', 'sshd', 'ssh_keys') || []

systemd_unit 'sshd.service' do
  action :nothing
end

directory keysdir do
  user 'root'
  mode 0o755
end

keys.each do |user, sshkeys|
  file ::File.join(keysdir, user) do
    content((['# Maintained by Chef'] + sshkeys).map { |v| "#{v}\n" }.join)
    user 'root'
    mode 0o644
  end
end

users = (keys.keys + (ck.dig('config', 'sshd', 'users') || [])).tap { |v| v.empty? ? nil : v }
config =
  ck['config']['sshd']['config']
  .transform_values { |v| case v; when true then 'yes'; when false then 'no'; else; v; end }
  .transform_values { |v| v.respond_to?(:each) ? v : [v] }
  .merge(
    AllowUsers: users,
    AuthorizedKeysFile: users.nil? ? nil : [::File.join(keysdir, '%u')],
  )
  .compact
  .transform_keys(&:to_s)

template ::File.join(root, 'sshd_config') do
  variables(cfg: config)
  user 'root'
  mode 0o644
  notifies :reload_or_restart, 'systemd_unit[sshd.service]'
end
