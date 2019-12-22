# Creating the rootfs from the Raspbian image always given root
# filesystems with the same UUID. If we find this UUID change it.

raspbian_uuid = '2ab3f8e1-7dc6-43f5-b0db-dd5759d51d4e'
return unless node['filesystem']['by_mountpoint']['/']['uuid'] == raspbian_uuid

ohai 'reload' do
  action :nothing
end

execute 'change uuid from Raspbian default' do
  command ['tune2fs', '-U', 'random', ::File.join('/dev/disk/by-uuid', raspbian_uuid)]
  notifies :reload, 'ohai[reload]', :immediately
end
