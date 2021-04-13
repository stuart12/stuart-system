name = 'dotnet'
return unless CfgHelper.activated? name

# https://docs.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual#manual-install
versions = [
  [
    '5f0f07ab-cd9a-4498-a9f7-67d90d582180/2a3db6698751e6cbb93ec244cb81cc5f/dotnet-sdk-5.0.202-linux-x64.tar.gz',
    'd2994d4e995bbab003b2d1b137807936fd96c94ba9982822893d62904aab54cf',
  ],
  [
    'ab82011d-2549-4e23-a8a9-a2b522a31f27/6e615d6177e49c3e874d05ee3566e8bf/dotnet-sdk-3.1.407-linux-x64.tar.gz',
    'a744359910206fe657c3a02dfa54092f288a44c63c7c86891e866f0678a7e911',
  ],
  [
    'b44d40e6-fa23-4f2d-a0a9-4199731f0b1e/5e62077a9e8014d8d4c74aee5406e0c7/dotnet-sdk-2.1.814-linux-x64.tar.gz',
    '2c16e62f1b19b32f30d56eeaeeb70b89acb4599b7523a20e159204c3741b46f0',
  ],
]
versions.map { |tail, checksum| [::File.join('https://download.visualstudio.microsoft.com/download/pr', tail), checksum] }
        .each do |url, checksum|
  remote_tar "#{name}-#{checksum}" do
    url url
    checksum checksum
    group CfgHelper.config(%w[work group])
    mode 0o754
    executable nil
    package name
  end
end

root = ::File.join(remote_tar_lib.where, name)
overlay = ::File.join(root, 'overlay')
executable = ::File.join(overlay, name)

shared_lib_pkg = 'libgit2-glib-1.0-0'
lib_dir = ::File.join(root, 'libs')
shared_lib = ::File.join('/usr/lib/x86_64-linux-gnu', "#{shared_lib_pkg.sub(/-[0-9]+$/, '')}.so.0")

package shared_lib_pkg

directory lib_dir

ruby_block 'check shared library exists' do
  block do
    raise "Missing #{shared_lib}"
  end
  not_if { ::File.exist? shared_lib }
end

link ::File.join(lib_dir, 'libgit2-106a5f2.so') do
  to shared_lib
end

lowerdir = versions
           .map(&:last)
           .map { |c| ::File.join(remote_tar_lib.where, name, remote_tar_lib.sub_directory, c) }
           .join(':')

mount overlay do
  fstype 'overlay'
  device 'none'
  options "lowerdir=#{lowerdir}"
  pass 0
  action %w[mount enable]
end

ruby_block 'check executable exists' do
  block do
    raise "Missing #{executable}"
  end
  not_if { ::File.exist? executable }
end

template ::File.join(remote_tar_lib.bin, name) do
  source 'shell_script.erb'
  variables(
    command: "#{executable} \"$@\"",
    env: { LD_LIBRARY_PATH: lib_dir },
  )
  manage_symlink_source false
  force_unlink true
  mode 0o755
end
