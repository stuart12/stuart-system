ck = 'stuart'

default[ck]['config']['wifi']['activate'] = false
default[ck]['config']['i2c']['activate'] = true
default[ck]['config']['mqtt']['activate'] = true

default[ck]['config']['networking']['ip'] = '192.168.0.25'
default[ck]['config']['networking']['mask'] = 24
default[ck]['config']['networking']['hostname'] = 'bedroom'
default[ck]['config']['networking']['dns'] = '192.168.0.254'
default[ck]['config']['networking']['gateway'] = '192.168.0.254'
