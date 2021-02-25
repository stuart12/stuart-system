name = 'dbeaver'
return unless CfgHelper.activated? name

cfg = CfgHelper.attributes(
  [name],
  version: '7.3.5',
  where: ::File.join('/opt', name),
  mode: 0o754,
  checksum: '1818234b9cb8efc6acbf21f208f9c0ce4115bd2908c08de0cfd64f84de79c9f9', # sha256sum
)

version = cfg['version']
url = "https://dbeaver.io/files/#{version}/dbeaver-ce-#{version}-linux.gtk.x86_64-nojdk.tar.gz"
tar = ::File.join(Chef::Config[:file_cache_path], "#{name}.tar.gz")
group = CfgHelper.config(%w[work group])
checksum = cfg['checksum']
where = cfg['where']

directory where do
  recursive true
  owner 'root'
  mode 0o755
end

remote_file tar do
  source url
  checksum cfg['checksum']
  owner 'root'
  mode 0o644
end

versions = "#{cfg['where']}/versions"

directory versions do
  owner 'root'
  group group
  mode cfg['mode']
end

installed = ::File.join(versions, checksum)
tmp = "#{installed}.tmp"
execute 'unzip' do
  command [
    "rm -rf #{tmp}",
    "mkdir -m 755 #{tmp}",
    "tar -C #{tmp} -x -f #{tar}",
    "chmod -R og=u,og-w  #{tmp}",
    "rm -rf #{installed}",
    "mv #{tmp} #{installed}",
  ].join(' && ')
  creates installed
end

link ::File.join(CfgHelper.config(%w[scripts bin]), name) do
  to ::File.join(versions, checksum, name, name)
end
