name = 'jetbrains_rider'
return unless CfgHelper.activated? name

cfg = CfgHelper.attributes(
  [name],
  url: 'https://download.jetbrains.com/rider/JetBrains.Rider-2021.1.5.tar.gz',
  checksum: 'f01edf992776a8990a9002b26000ba2b4c24419d052b2c332e7ec9740dc4bd9e', # sha256sum
  where: '/opt',
  mode: 0o754,
  strip_components: 1,
)

remote_tar name do
  url cfg['url']
  checksum cfg['checksum']
  group CfgHelper.config(%w[work group])
  mode cfg['mode']
  where cfg['where']
  strip_components cfg['strip_components']
  executable nil
end

executable = ::File.join(cfg['where'], name, remote_tar_lib.sub_directory, cfg['checksum'], 'bin', 'rider.sh')

template ::File.join(remote_tar_lib.bin, name) do
  source 'shell_script.erb'
  variables(
    command: "#{executable} \"$@\"",
    env: { IDE_PROPERTIES_PROPERTY: '-Didea.system.path=~/.cache/JetBrains/Rider' },
  )
  manage_symlink_source true
  force_unlink true
  mode 0o755
end

ruby_block "check #{executable} is executable" do
  block do
    raise "Cannot execute #{executable}"
  end
  not_if { ::File.executable? executable }
end
