return unless CfgHelper.activated? 'abank'

executable = '/usr/local/lib/abank'
src = ::File.join(CfgHelper.config(%w[git directory]), 'github.com', 'stuart12', 'abank')
build = [
  "cp -sr #{src} .",
  "cd #{::File.basename(src)}",
  'autoreconf --install',
  './configure --quiet',
  'make >&2',
  'tar -cC src abank',
].join(' && ')
properties = {
  DynamicUser: 'yes',
  WorkingDirectory: '/tmp',
  ProtectHome: true,
  ProtectSystem: 'strict',
  PrivateDevices: true,
  PrivateNetwork: true,
  PrivateUsers: true,
  Environment: 'QT_SELECT=4', # FIXME: hack, should fix abank
  LockPersonality: true,
}.map { |k, v| "--property=#{k}='#{v}'" }.join(' ')
execute 'compile' do
  command [
    't=$(mktemp -t compileXXXXXX)',
    "trap 'rm $t' 0",
    "systemd-run #{properties} --pipe sh -c '#{build}' > $t",
    "tar --no-same-owner -xC #{::File.dirname(executable)} -f $t",
    "chmod 755 #{executable}",
  ].join(' && ')
  action :nothing
end

pkgs = %w[autoconf libqtcore4 libqt4-qt3support libqt4-dev-bin libqt4-dev]
pkgs.each do |p|
  paquet p do
    action :nothing # FIXME: may remove qt5 programs
  end
end

git src do
  repository ::File.join('https://', 'github.com', 'stuart12', 'abank') # FIXME: should be resource
  user 'root'
  notifies :run, 'execute[compile]'
end

ruby_block 'compile' do
  block {}
  pkgs.each do |p|
    notifies :install, "paquet[#{p}]"
  end
  notifies :run, 'execute[compile]'
  not_if { ::File.exist? executable }
end

dir = '$HOME/Syncthing'
file = 'dynamic/accounts'

template ::File.join(CfgHelper.config['scripts']['bin'], ::File.basename(executable)) do # FIXME: is hack
  variables(
    noexec: true,
    command: "[ -r #{dir}/#{file} ] && #{executable} #{dir}/#{file} || #{executable} #{dir}/stuart/#{file}",
  )
  source 'shell_script.erb'
  mode 0o755
  owner 'root'
end
