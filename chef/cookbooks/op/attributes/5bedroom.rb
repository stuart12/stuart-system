ck = 'stuart'

return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '2ab3f8e1-7dc6-43f5-b0db-dd5759d51d4e'

default[ck]['config']['firewall']['activate'] = true
default[ck]['config']['delcom-clock']['activate'] = true
default[ck]['config']['snapclient']['activate'] = true
default[ck]['config']['wifi']['activate'] = false
default[ck]['config']['i2c']['activate'] = true
default[ck]['config']['mqtt']['activate'] = true
default[ck]['config']['homeassistant']['activate'] = true
default[ck]['config']['homeassistant']['blinksticklight'] = true
default[ck]['config']['homeassistant']['keyboard'] = true
default[ck]['config']['homeassistant']['audio'] = true

default[ck]['config']['networking']['ip'] = '192.168.0.25'
default[ck]['config']['networking']['mask'] = 24
default[ck]['config']['networking']['hostname'] = 'bedroom'
default[ck]['config']['networking']['dns'] = '192.168.0.254'
default[ck]['config']['networking']['gateway'] = '192.168.0.254'
