name = 'dotnet'
return unless CfgHelper.activated? name

checksum = 'a744359910206fe657c3a02dfa54092f288a44c63c7c86891e866f0678a7e911'
remote_tar name do
  url 'https://download.visualstudio.microsoft.com/download/pr/ab82011d-2549-4e23-a8a9-a2b522a31f27/6e615d6177e49c3e874d05ee3566e8bf/dotnet-sdk-3.1.407-linux-x64.tar.gz'
  checksum checksum
  group CfgHelper.config(%w[work group])
  mode 0o754
  executable nil
end

pkg = 'libgit2-glib-1.0-0'
package pkg

root = ::File.join(remote_tar_lib.where, name)
lib_dir = ::File.join(root, 'libs')

directory lib_dir

link ::File.join(lib_dir, 'libgit2-106a5f2.so') do
  to ::File.join('/usr/lib/x86_64-linux-gnu', "#{pkg.sub(/-[0-9]+$/, '')}.so.0")
end

template ::File.join(remote_tar_lib.bin, name) do
  source 'shell_script.erb'
  variables(
    command: "#{::File.join(root, remote_tar_lib.sub_directory, checksum, name)} \"$@\"",
    env: { LD_LIBRARY_PATH: lib_dir },
  )
  manage_symlink_source false
  force_unlink true
  mode 0o755
end

return if 0.zero?

ld_dir = ::File.join('/opt/chef-libs', name)

dir ld_dir do
  mode o0755
end
