ck = 'stuart'

return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '4a3f-4e9f-8d33-be9f2ba5ffce'

default[ck]['config']['networking']['hostname'] = 'bathroom'

default[ck]['config']['boot']['config']['leds'] = false

default[ck]['config']['snapclient']['activate'] = true
default[ck]['config']['wifi']['activate'] = true
default[ck]['config']['homeassistant']['activate'] = false
default[ck]['config']['homeassistant']['keyboard'] = true
