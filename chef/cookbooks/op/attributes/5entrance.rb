return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '5337d0a6-2727-4039-beed-7b3513cd62c3'

CfgHelper.set_config['snapclient']['activate'] = true
CfgHelper.set_config['snapclient']['alsa_device'] = 'DAC'

CfgHelper.set_config['networking']['hostname'] = 'entrance'

CfgHelper.set_config['homeassistant']['activate'] = true
CfgHelper.set_config['homeassistant']['keyboard'] = true
CfgHelper.set_config['homeassistant']['IR'] = true
CfgHelper.set_config['homeassistant']['z-wave'] = true
CfgHelper.set_config['homeassistant']['use_config_file'] = false

CfgHelper.set_config['scanner']['activate'] = true

CfgHelper.set_config['homeassistant'].tap do |homeassistant|
  homeassistant['activate'] = true
  homeassistant['keyboard'] = true
  homeassistant['configuration'].tap do |configuration|
    configuration['zwave'].tap do |zwave|
      zwave['network_key'] = CfgHelper.secrets['homeassistant']['z_wave_key'] || raise('missing z-wave key')
      zwave['usb_path'] = '/dev/z-wave'
    end
  end
end

# https://www.mess.org/2019/03/05/How-to-add-support-for-a-new-remote-using-lircd-conf-file/
keycodes = { # Cambridge_Audio_Azuz_540A
  Power_Off: 0x100f,
  Vol_Up: 0x1010,
  Vol_Down: 0x1011,
  Aux_Phono: 0x1004,
  CD: 0x1005,
}

Hass.shell_command(
  {
    amp_off: [{ Vol_Down: 41 }, { Vol_Up: 7 }, { Power_Off: 1 }],
    amp_on: [{ Aux_Phono: 1 }],
    amp_volume_down: [{ Vol_Down: 1 }],
    amp_volume_up: [{ Vol_Up: 1 }],
  }.map do |name, scancodes|
    [
      name,
      ['set -x;', 'ir-ctl', '--verbose', '--emitters=3']
      .concat(scancodes.map { |sc| sc.flat_map { |code, count| ['-S', "rc5:#{keycodes[code]}"] * count } })
      .join(' '),
    ]
  end.to_h,
)

{ Up: %w[rightbrace plus], Down: %w[leftbrace minus] }.each do |direction, keys|
  Hass.automation(
    "Volume #{direction}",
    keys.flat_map { |key| Hass.trigger_for_key(key) } +
    [{ platform: 'mqtt',
       topic: 'message',
       payload: "living volume #{direction.downcase}" }],
    [
      { service: 'media_player.volume_mute',
        data: {
          entity_id: "media_player.snapcast_client_#{node.name}",
          is_volume_muted: false,
        } },
      service: "shell_command.amp_volume_#{direction.downcase}",
    ],
  )
end

Hass.script(
  'reset_local_volume',
  service: 'shell_command.amp_off',
)

Hass.automation(
  'Amp On',
  [
    { platform: 'template',
      value_template: "{{ is_state_attr('media_player.snapcast_client_#{node.name}', 'is_volume_muted', false) }}",
      for: 3 },
  ],
  service: 'shell_command.amp_on',
)

hosts = CfgHelper.config['networking']['hosts'].keys

Hass.automation(
  'Leaving',
  %w[Space 0].flat_map { |key| Hass.trigger_for_key(key) },
  hosts.sort.map do |host|
    { service: 'media_player.volume_mute',
      data: {
        entity_id: "media_player.snapcast_client_#{host}",
        is_volume_muted: true,
      } }
  end,
)
