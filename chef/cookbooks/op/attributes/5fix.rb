ck = 'stuart'

return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '13d021a2-3b94-43d3-8c28-bca013bf76e9'

default[ck]['config']['delcom-clock']['activate'] = true
