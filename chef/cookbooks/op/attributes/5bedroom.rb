return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '0097b564-4a3f-4e9f-8d33-be9f2ba5ffce'

CfgHelper.set_config['networking']['hostname'] = 'bedroom'

CfgHelper.set_config['boot']['config']['leds'] = false

CfgHelper.set_config['delcom-clock']['activate'] = true
CfgHelper.set_config['snapclient']['activate'] = true
CfgHelper.set_config['wifi']['activate'] = false
CfgHelper.set_config['i2c']['activate'] = true
CfgHelper.set_config['mqtt']['activate'] = true
CfgHelper.set_config['homeassistant'].tap do |homeassistant|
  homeassistant['activate'] = true
  homeassistant['blinksticklight'] = true
  homeassistant['keyboard'] = true
  homeassistant['audio'] = true
  homeassistant['use_config_file'] = true
end
