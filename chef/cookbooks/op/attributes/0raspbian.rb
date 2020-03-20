ck = 'stuart'

return unless platform? 'raspbian'

default[ck]['config']['users']['password'] = '$1$PGiJPcck$lQpIrARzg6Aa5Mh/Sg9wO1'
default[ck]['config']['users']['users'] = node['etc']['passwd'].select { |_, cfg| cfg['uid'].between?(1000, 2000) }.keys

default[ck]['config']['sshd']['activate'] = true
default[ck]['config']['firewall']['activate'] = true

default[ck]['config']['boot']['config']['leds'] = true

CfgHelper.add_package 'ruby-shadow' # required by Chef's password resource
