return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '9598eec9-7ec3-4b0f-b731-f5ee47716a3e'

# Do a Debian install using the expert mode. Do not create users.
# After configuring the disks, open a shell,
# - umount /target/boot/efi
# - umount /target/boot
# - btrfs subvolume create /target/root
# - mv /target/etc /target/media /target/root/
# - btrfs subvolume list /target
# - btrfs subvolume set-default XXX
# - grep target /proc/mounts
# - umount /target
# - mount YYY /target
# Continue the install, after the first boot
# - checkout this repo
# - run converge

%w[
  vim-gtk3
].each do |pkg|
  CfgHelper.add_package pkg
end

CfgHelper.activate 'desktop'
