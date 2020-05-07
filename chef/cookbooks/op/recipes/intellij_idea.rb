return unless CfgHelper.activated? 'intellij_idea'

name = 'intellij'
# https://www.jetbrains.com/idea/download/download-thanks.html?platform=linux
cfg = CfgHelper.attributes(
  [name],
  url: 'https://download.jetbrains.com/idea/ideaIU-2020.1.tar.gz',
  checksum: 'b8f352cf3ca59613ce02692911e8ab271c7d2365d4a5c6e6e0efb39c71d37412',
  where: ::File.join('/opt', name),
  mode: 0o754,
)

tar = ::File.join(Chef::Config[:file_cache_path], "#{name}.tar.gz")
symlink = ::File.join(cfg['where'], name)
executable = ::File.join(symlink, 'bin', 'idea.sh')
group = CfgHelper.config(%w[work group])

directory cfg['where'] do
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

directory "set group on #{cfg['where']}" do
  path cfg['where']
  owner 'root'
  group group
  mode cfg['mode']
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
