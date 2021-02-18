return unless CfgHelper.activated? 'npm'

version = '6.6.0'
home = ::File.join(Chef::Config[:file_cache_path], 'npm-hack')
where = '/lib/npm-chef'
executable = ::File.join(where, 'bin/npm')

execute [
  "rm -rf #{home}",
  "mkdir -p -m 0700 #{home}/.cache/npm/lib",
  "npm install --cache /tmp --global npm@#{version}",
  "rm -rf #{where}",
  "cp -r #{home}/.cache/npm #{where}",
  "chmod -R og=u,og-w #{where}",
  "rm -r #{home}",
].join(' && ') do
  not_if { ::File.exist?(executable) && version == `#{executable} --version`.strip }
  environment(
    {
      'HOME' => home,
    },
  )
end

file '/etc/profile.d/chef-npm' do
  action :delete
end

file '/etc/profile.d/chef-npm.sh' do
  content "PATH=#{where}/bin:$PATH\n"
  mode 0o644
  owner 'root'
end
