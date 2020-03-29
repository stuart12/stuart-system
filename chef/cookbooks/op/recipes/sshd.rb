ck = node['stuart']

return unless ck.dig('config', 'sshd', 'activate')

root = '/etc/ssh'
keysdir = ::File.join(root, 'authorized_keys')

ssh_keys = (ck.dig('config', 'users', 'ssh_keys') || {}).select { |_, key| key }.map { |who, key| "#{key} #{who}" }

systemd_unit 'sshd.service' do
  action :nothing
end

directory keysdir do
  user 'root'
  mode 0o755
end

users_raw = ck.dig('config', 'users', 'users') || []
users = users_raw.respond_to?(:keys) ? users_raw.keys : users_raw

(users.respond_to?(:keys) ? users.keys : users).each do |user|
  file ::File.join(keysdir, user) do
    content((['# Maintained by Chef'] + ssh_keys).map { |v| "#{v}\n" }.join)
    user 'root'
    mode 0o444
  end
end

config =
  ck['config']['sshd']['config']
  .transform_values { |v| case v; when true then 'yes'; when false then 'no'; else; v; end }
  .merge(
    AllowUsers: users,
    AuthorizedKeysFile: ::File.join(keysdir, '%u'),
    Subsystem: ['sftp', '/usr/lib/openssh/sftp-server'],
  )
  .transform_values { |v| v.respond_to?(:each) ? v : [v] }
  .transform_keys(&:to_s)

package 'openssh-server' do
  action :upgrade
end

file ::File.join(root, 'sshd_config.d', 'chef.conf') do
  action :delete
end

template ::File.join(root, 'sshd_config') do # sshd on buster does not have Include
  source 'sshd_config.erb'
  variables(cfg: config)
  user 'root'
  mode 0o444
  notifies :reload_or_restart, 'systemd_unit[sshd.service]', :delayed
end

systemd_unit 'sshd.service' do
  action :start
end
