return unless CfgHelper.activated? 'intellij_idea'

name = 'intellij'
# https://www.jetbrains.com/idea/download/download-thanks.html?platform=linux
cfg = CfgHelper.attributes(
  [name],
  version: '2020.3.2',
  checksum: '86590262232e23a6d4351a8385a0dd3c85f8b2846323c1586e44c86e019a4b38', # sha256sum
  where: '/opt',
  mode: 0o754,
  watches: 512 * 1024,
)

remote_tar name do
  url "https://download.jetbrains.com/idea/ideaIU-#{cfg['version']}.tar.gz"
  checksum cfg['checksum']
  group CfgHelper.config(%w[work group])
  mode cfg['mode']
  where cfg['where']
  executable nil
end

target = ::File.join(cfg['where'], name, 'versions', cfg['checksum'])
symlink = ::File.join(target, cfg['version'])

ruby_block 'symlink' do
  block do
    entries = ::Dir.entries(target).reject { |e| e.start_with? '.' }
    raise "expected one entry in #{target}, found #{entries}" unless entries.length == 1

    ::FileUtils.mv(::File.join(target, entries.first), symlink)
  end
  not_if { ::File.exist? symlink }
end

properties = ::File.join('/usr/local/share', name, 'idea.properties')

directory ::File.dirname(properties) do
  mode 0o755
  owner 'root'
end

template properties do
  variables(
    lines: [
      'idea.system.path=${user.home}/.cache/${idea.paths.selector}/system',
      'idea.log.path=${user.home}/.cache/${idea.paths.selector}/log',
    ],
  )
  mode 0o644
  owner 'root'
  source 'lines.erb'
end

executable = ::File.join(symlink, 'bin', 'idea.sh')

template ::File.join(CfgHelper.config(%w[scripts bin]), 'idea') do
  variables(
    env: {
      IDEA_PROPERTIES: properties,
    },
    command: "#{executable} \"$@\"",
  )
  source 'shell_script.erb'
  mode 0o754
  group group
end

ruby_block 'raise' do
  block do
    Chef::Log.fatal "missing #{executable}"
    raise
  end
  not_if { ::File.exist? executable }
end

return if 0.zero?

sysctl name do # FIXME: rewrite for chef 13
  comment 'https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit'
  key 'fs.inotify.max_user_watches'
  value cfg['watches']
end
