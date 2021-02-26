resource_name :remote_tar

property :name, String, name_property: true
property :url, String
property :checksum, String
property :bin, String, default: '/usr/local/bin'
property :mode, Integer, default: 0o755
property :group, String, default: 'root'
property :where, String, default: '/opt'
property :executable, [nil, String], default: nil
property :target, [nil, String], default: nil

action :manage do
  tar = ::File.join(Chef::Config[:file_cache_path], "#{new_resource.name}.tar.gz")

  remote_file tar do
    source new_resource.url
    checksum new_resource.checksum
    owner 'root'
    mode 0o644
  end

  installation = ::File.join(new_resource.where, new_resource.name)

  directory installation do
    recursive true
    owner 'root'
    mode 0o755
  end

  versions = ::File.join(installation, 'versions')

  directory versions do
    owner 'root'
    group new_resource.group
    mode new_resource.mode
  end

  installed = ::File.join(versions, new_resource.checksum)
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

  link new_resource.target do
    to ::File.join(installed, new_resource.executable)
  end unless new_resource.target.nil? || new_resource.executable.nil?
end
