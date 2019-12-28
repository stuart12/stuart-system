ck = 'stuart'

return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '0097b564-4a3f-4e9f-8d33-be9f2ba5ffce'

default[ck]['config']['networking']['hostname'] = 'bedroom'

default[ck]['config']['boot']['config']['leds'] = false

default[ck]['config']['delcom-clock']['activate'] = true
default[ck]['config']['snapclient']['activate'] = true
default[ck]['config']['wifi']['activate'] = false
default[ck]['config']['i2c']['activate'] = true
default[ck]['config']['mqtt']['activate'] = true
default[ck]['config']['homeassistant']['activate'] = true
default[ck]['config']['homeassistant']['blinksticklight'] = true
default[ck]['config']['homeassistant']['keyboard'] = true
default[ck]['config']['homeassistant']['audio'] = true
default[ck]['config']['homeassistant']['use_config_file'] = true
