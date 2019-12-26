ck = 'stuart'

return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '3442860e-35fd-41fd-b73d-30d4ccf50a8a'

default[ck]['config']['networking']['hostname'] = 'bathroom'

default[ck]['config']['boot']['config']['leds'] = false

default[ck]['config']['snapclient']['activate'] = true
default[ck]['config']['wifi']['activate'] = true
default[ck]['config']['homeassistant']['activate'] = false
default[ck]['config']['homeassistant']['keyboard'] = true
