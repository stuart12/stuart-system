return unless CfgHelper.activated? 'npm'

version = '6.6.0'
where = '/opt/npm'
user = 'games'
tmp = ::File.join(where, 'tmp')
bin = ::File.join(where, 'bin')
node_version = '10.13.0'
work = ::File.join(tmp, 'work')
cache = ::File.join(work, '_cache')

versions = "#{node_version}!#{version}"

directory where do
  mode 0o754
  group CfgHelper.config(%w[work group])
end

directory tmp do
  user user
  mode 0o700
end

ready = ::File.join(tmp, versions)

execute 'get' do
  command [
    "[ ! -d #{work} ] || rm -r #{work}",
    "mkdir -p -m 0700 #{cache}",
    "npm install --cache #{cache} --global npm@#{version}",
    "npm install --cache #{cache} --global node@#{node_version}",
    "mv #{work}/.cache/npm #{ready}",
  ].join(' && ')
  environment(
    {
      'HOME' => work,
    },
  )
  user user
  creates ready
end

staging = ::File.join(where, 'staging')
installed = ::File.join(where, versions)

execute 'move' do
  command [
    "cp -r #{ready} #{staging}",
    "chmod og=u,og-w #{staging}",
    "mv #{staging} #{installed}",
  ].join(' && ')
  creates installed
end

current = ::File.join(where, 'current')
executables = ::File.join(current, 'bin')

link ::File.join(executables, 'nodejs') do
  to 'node'
end

link current do
  to versions
end

directory bin do
  mode 0o755
  user 'root'
end

%w[npm npx].each do |script|
  template ::File.join(bin, script) do
    manage_symlink_source false
    force_unlink true
    variables(
      command: "#{::File.join(executables, 'node')} #{::File.join(executables, script)} \"$@\"",
    )
    mode 0o755
    owner 'root'
    source 'shell_script.erb'
  end
end

file '/etc/profile.d/chef-npm.sh' do
  content "PATH=#{bin}:#{current}/bin:$PATH\n"
  mode 0o644
  owner 'root'
end
