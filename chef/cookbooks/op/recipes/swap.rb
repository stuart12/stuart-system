return unless CfgHelper.activated? 'swap'
# https://wiki.archlinux.org/index.php/Dm-crypt/Swap_encryption

return unless node['memory']['swap']['total'].start_with? '0'

swap_tag = CfgHelper.attributes(%w[swap device_tag], 'swapcrypted')

raise "swap tag #{swap_tag} too short" unless swap_tag.length > 3

boots = node['filesystem']['by_mountpoint']['/boot']['devices']
raise "expected 1 boot device, found: #{boots}" unless boots.length == 1
boot_disk = ::File.basename(boots.first[0...-1])

swap_devices = Dir["/dev/disk/by-partlabel/*#{swap_tag}"].select do |path|
  ::File.basename(::File.readlink(path))[0...-1] == boot_disk
end

raise "expected 1 swap device on #{boot_disk}, found #{swap_devices}" unless swap_devices.length == 1

swap_symlink = swap_devices.first
swap_device = ::File.realpath(swap_symlink)

current = node['filesystem']['by_device'][swap_device]
raise "swap #{swap_device} already used: #{current}" unless current == { 'mounts' => [] }

uuid = ::SecureRandom.uuid

# using an ext2 fs causes cryptdisks_start to refuse to use the partition
execute "mkswap -U #{uuid} -L chef_swap_part #{swap_device} 1"

mapper_label = CfgHelper.attributes(%w[swap mapper_label], 'chef_swap')

append '/etc/crypttab' do
  line [
    mapper_label,
    "UUID=#{uuid}",
    '/dev/urandom',
    CfgHelper.attributes(%w[swap crypt_options], 'swap,offset=2048,cipher=aes-xts-plain64,size=512,discard'),
  ].join(' ')
end

execute "cryptdisks_start #{mapper_label}"

mapper = ::File.join('/dev/mapper', mapper_label)

swap_options = CfgHelper.attributes(%w[swap swap_options], 'discard')

append '/etc/fstab' do
  line "#{mapper} none swap #{swap_options} 0 0"
end

execute "swapon #{mapper}"
