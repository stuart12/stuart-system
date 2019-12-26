ck = 'stuart'

return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '5337d0a6-2727-4039-beed-7b3513cd62c3'

default[ck]['config']['snapclient']['activate'] = true
default[ck]['config']['snapclient']['alsa_device'] = 'DAC'

default[ck]['config']['networking']['hostname'] = 'entrance'

default[ck]['config']['homeassistant']['activate'] = true
default[ck]['config']['homeassistant']['keyboard'] = true
default[ck]['config']['homeassistant']['IR'] = true
default[ck]['config']['homeassistant']['z-wave'] = true

default[ck]['config']['scanner']['activate'] = true
