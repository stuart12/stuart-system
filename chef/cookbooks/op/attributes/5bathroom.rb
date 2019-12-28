ck = 'stuart'
name = 'bathroom'

return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '3442860e-35fd-41fd-b73d-30d4ccf50a8a'

default[ck]['config']['networking']['hostname'] = name

default[ck]['config']['boot']['config']['leds'] = false

default[ck]['config']['snapclient']['activate'] = true
default[ck]['config']['wifi']['activate'] = true

CfgHelper.set_config['homeassistant'].tap do |hass|
  hass['activate'] = true
  hass['keyboard'] = true
  hass['yaml'].tap do |yaml|
    yaml['media_player'] = [
      {
        'platform' => 'snapcast',
        'host' => 'kooka',
      },
    ]
  end
end
