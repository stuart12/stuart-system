return unless CfgHelper.activated? 'intellij_idea'

name = 'intellij'
# https://www.jetbrains.com/idea/download/download-thanks.html?platform=linux
cfg = CfgHelper.attributes(
  [name],
  url: 'https://download.jetbrains.com/idea/ideaIU-2020.2.3.tar.gz',
  checksum: 'ca2c9ea47b18f49541020f2d0076066240a5cc6c98ddbcce2a643f47fdf7c260', # sha256sum
  where: ::File.join('/opt', name),
  mode: 0o754,
  watches: 512 * 1024,
)

tar = ::File.join(Chef::Config[:file_cache_path], "#{name}.tar.gz")
symlink = ::File.join(cfg['where'], name)
executable = ::File.join(symlink, 'bin', 'idea.sh')
group = CfgHelper.config(%w[work group])

directory "clean #{cfg['where']}" do
  path cfg['where']
  recursive true
  action :delete
  not_if { ::File.exist? symlink }
end

remote_file tar do
  source cfg['url']
  checksum cfg['checksum']
  owner 'root'
  mode 0o644
  notifies :delete, "directory[#{cfg['where']}]", :immediately
end

ruby_block 'symlink' do
  block do
    entries = ::Dir.entries(cfg['where']).reject { |e| e.start_with? '.' }
    raise "expected one entry in #{cfg['where']}, found #{entries}" unless entries.length == 1

    ::FileUtils.ln_s(entries.first, symlink)
    raise "missing executable #{executable}" unless ::File.exist? executable
  end
  action :nothing
end

archive_file tar do
  destination cfg['where']
  notifies :run, 'ruby_block[symlink]'
end

directory cfg['where'] do
  owner 'root'
  group group
  mode cfg['mode']
  recursive true
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

sysctl name do
  comment 'https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit'
  key 'fs.inotify.max_user_watches'
  value cfg['watches']
end
