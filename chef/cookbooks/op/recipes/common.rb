systemd_unit 'chef-client' do
  action %i[stop disable]
end

cookbook_file '/etc/inputrc' do
  mode 0o644
  user 'root'
end

locales = CfgHelper.attributes(
  ['locale', 'UTF-8'],
  %w[
    en_AU
    en_GB
    en_IE
    fr_FR
  ].map { |locale| [locale, true] }.to_h,
).select { |_, v| v }.keys

execute 'locale-gen' do
  action :nothing
end
template '/etc/locale.gen' do
  variables(utf8: locales)
  notifies :run, 'execute[locale-gen]'
  mode 0o644
  user 'root'
end

template '/etc/gitconfig' do
  user 'root'
  mode 0o644
  variables(
    name: CfgHelper.config['git']['name'],
    email: CfgHelper.config['git']['email'],
  )
end

['profile.d/shell_global_profile.sh'].each do |path|
  cookbook_file ::File.join('/etc/', path) do
    mode 0o644
    user 'root'
  end
end

cookbook_file '/etc/bash.bashrc' do
  source 'bashrc'
  user 'root'
  mode 0o644
end

mount '/tmp' do
  pass 0
  fstype 'tmpfs'
  device 'tmpfs'
  options %w[atime size=1023M]
  action :enable # mount at next boot
end

file '/usr/local/bin/l' do
  content "#!/bin/sh\n# Maintained by Chef\nexec /bin/ls -la \"$@\"\n"
  mode 0o755
  owner 'root'
end
