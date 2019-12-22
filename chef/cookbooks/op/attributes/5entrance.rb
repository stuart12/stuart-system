ck = 'stuart'

return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '5337d0a6-2727-4039-beed-7b3513cd62c3'

default[ck]['config']['snapclient']['activate'] = true

default[ck]['config']['networking']['ip'] = '192.168.0.30'
default[ck]['config']['networking']['mask'] = 24
# default[ck]['config']['networking']['hostname'] = 'entrance'
default[ck]['config']['networking']['dns'] = '192.168.0.254'
default[ck]['config']['networking']['gateway'] = '192.168.0.254'
