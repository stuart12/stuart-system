return unless CfgHelper.activated? 'npm'

version = '6.6.0'
home = ::File.join(Chef::Config[:file_cache_path], 'npm-hack')
where = '/lib/npm-chef'
executable = ::File.join(where, 'bin/npm')
user = 'games'
node_version = '10.13.0'
cache = ::File.join(home, '_cache')
node = ::File.join(where, 'bin', 'node')
nodejs = ::File.join(where, 'bin', 'nodejs')

directory home do
  owner user
  mode 0o755
end

execute 'get' do
  command [
    "find #{home}/. -mindepth 1 -delete",
    "mkdir -p -m 0700 #{home}/.cache/npm/lib",
    "npm install --cache #{cache} --global npm@#{version}",
    "npm install --cache #{cache} --global node@#{node_version}",
    "ln -s node #{home}/.cache/npm/bin/nodejs",
    "chmod -R og=u,og-w #{home}",
  ].join(' && ')
  environment(
    {
      'HOME' => home,
    },
  )
  user user
  action :nothing
end

execute 'install' do
  command [
    "rm -rf #{where}", # FIXME: not atomic
    "cp -r #{home}/.cache/npm #{where}",
  ].join(' && ')
  not_if do
    ::File.exist?(executable) && version == `sudo -u #{user} #{executable} --version`.strip &&
      ::File.exist?(node) && "v#{node_version}" == `sudo -u #{user} #{node} --version`.strip &&
      ::File.exist?(nodejs) && "v#{node_version}" == `sudo -u #{user} #{nodejs} --version`.strip
  end
  notifies :run, 'execute[get]', :before
end

file '/etc/profile.d/chef-npm' do
  action :delete
end

file '/etc/profile.d/chef-npm.sh' do
  content "PATH=#{where}/bin:$PATH\n"
  mode 0o644
  owner 'root'
end
