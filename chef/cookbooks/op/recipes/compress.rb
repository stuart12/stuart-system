root = node['filesystem']['by_mountpoint']['/']
mount '/' do
  device root['devices'].first
  options root['mount_options'] + ['compress=zstd']
  action :remount
  supports remount: true
  only_if { root['fs_type'] == 'btrfs' }
  only_if { root['devices'].length == 1 }
  not_if { root['mount_options'].any? { |o| o.split('=').first == 'compress' } }
end
