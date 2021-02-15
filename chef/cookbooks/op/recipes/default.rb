include_recipe '::change_uuid'
include_recipe '::compress'
include_recipe '::swap'
include_recipe '::network'
include_recipe '::attribute_driven'
include_recipe '::early'

# all the following recipes should be order insenstive

include_recipe '::x11'
include_recipe '::firefox'
include_recipe '::raspbian'
include_recipe '::firewall'
include_recipe '::sshd'
include_recipe '::wifi'
include_recipe '::i2c'
include_recipe '::homeassistant'
include_recipe '::snapclient'
include_recipe '::boot_config'
include_recipe '::scanner'
include_recipe '::desktop'
include_recipe '::vpn'
include_recipe '::gradle'
include_recipe '::zoom'
include_recipe '::slack'
include_recipe '::bluejeans'
include_recipe '::kooka'
include_recipe '::intellij_idea'
include_recipe '::common'
include_recipe '::btrfs'
include_recipe '::syncthing'
include_recipe '::abank'
include_recipe '::sane'
include_recipe '::etesync_dav'
include_recipe '::photo_transforms'
include_recipe '::npm'
