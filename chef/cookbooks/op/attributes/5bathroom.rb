ck = 'stuart'
name = 'bathroom'

return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '3442860e-35fd-41fd-b73d-30d4ccf50a8a'

default[ck]['config']['networking']['hostname'] = name

default[ck]['config']['boot']['config']['leds'] = false

default[ck]['config']['snapclient']['activate'] = true
default[ck]['config']['wifi']['activate'] = true

snap = "media_player.snapcast_client_#{name}"
def mute_action(state, snap)
  {
    service: 'media_player.volume_mute',
    data: {
      entity_id: snap,
      is_volume_muted: state,
    },
  }
end

def keypad_trigger(key)
  {
    platform: 'event',
    event_type: 'keyboard_remote_command_received',
    event_data: {
      key_code: KeyCodes.keypad(key),
    },
  }
end

def keypad(alias_name, key, actions)
  {
    alias: alias_name,
    trigger: keypad_trigger(key),
    action: actions,
  }
end

automations = [
  keypad('Off', 'Enter', [mute_action(true, snap)]),
] + { 'Plus' => '+', 'Minus' => '-' }.map do |key, operation|
  keypad("Volume #{key} #{operation}", key,
         [
           mute_action(false, snap),
           {
             service: 'media_player.volume_set',
             entity_id: snap,
             data_template: {
               volume_level: "{{ state_attr('#{snap}', 'volume_level') | float #{operation} 0.1 }}",
             },
           },
         ])
end

CfgHelper.set_config['homeassistant'].tap do |hass|
  hass['activate'] = true
  hass['keyboard'] = true
  hass['configuration'].tap do |yaml|
    yaml['keyboard_remote'] = [
      {
        'device_name' => 'SEMICO USB Keyboard',
        'type' => 'key_down',
      },
    ]
    yaml['media_player'] = [
      {
        'platform' => 'snapcast',
        'host' => 'kooka',
      },
    ]
  end
  hass['automation'] = automations
end