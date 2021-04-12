resource_name :remote_tar

property :name, String, name_property: true
property :url, String
property :checksum, String # The SHA-256 checksum of the file
property :bin, [nil, String], default: nil
property :mode, Integer, default: 0o755
property :group, String, default: 'root'
property :where, [nil, String], default: nil
property :executable, [nil, String], name_property: true
property :target, [nil, String], name_property: true
property :package, String, name_property: true

# rubocop:disable Metrics/BlockLength
action :manage do
  tar = ::File.join(Chef::Config[:file_cache_path], "#{new_resource.name}.tar.gz")

  remote_file tar do
    source new_resource.url
    checksum new_resource.checksum
    owner 'root'
    mode 0o644
  end

  bin = new_resource.bin || remote_tar_lib.bin
  where = new_resource.where || remote_tar_lib.where
  installation = ::File.join(where, new_resource.package)

  directory installation do
    recursive true
    owner 'root'
    mode 0o755
  end

  versions = ::File.join(installation, remote_tar_lib.sub_directory)

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
      "tar -C #{tmp} --no-same-owner -x -f #{tar}",
      "chmod -R og=u,og-w  #{tmp}",
      "rm -rf #{installed}",
      "mv #{tmp} #{installed}",
    ].join(' && ')
    creates installed
  end

  unless new_resource.target.nil? || new_resource.executable.nil?
    link ::File.join(bin, new_resource.target) do
      to ::File.join(installed, new_resource.executable)
    end
  end
end
# rubocop:enable Metrics/BlockLength
