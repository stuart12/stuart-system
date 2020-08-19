return unless CfgHelper.activated? 'gradle'

%w[
  curl
  npm
  openjdk-8-jdk
].each do |pkg|
  paquet pkg
end

zip = ::File.join(Chef::Config[:file_cache_path], 'gradle.zip')
cfg = CfgHelper.config['gradle']
install = cfg['install']
tmp = "#{install}.tmp"
checksum = cfg['checksum'] || raise('missing checksum for gradle')
atomic = "#{install}.#{checksum}"
pattern = 'gradle-*'

remote_file zip do
  source cfg['url']
  checksum checksum
  owner 'root'
  mode 0o644
end

command = [
  "rm -rf #{tmp}",
  "mkdir -m 700 #{tmp}",
  "cd #{tmp}",
  "unzip #{zip}",
  "chown -R root:root #{pattern}",
  "chmod -R og=u,og-w #{pattern}",
  "chmod #{cfg['permissions']} #{pattern}",
  "chgrp #{cfg['group']} #{pattern}",
  "mv #{pattern} #{atomic}",
  'cd ..',
  "rmdir #{tmp}",
].join(' && ')

execute 'unpack gradle' do
  command command
  creates atomic
end

link install do
  to ::File.basename(atomic)
end

template '/etc/profile.d/gradle.sh' do
  variables(
    bin: ::File.join(install, 'bin'),
    java: '/usr/lib/jvm/java-8-openjdk-amd64',
  )
  mode 0o644
  owner 'root'
end
