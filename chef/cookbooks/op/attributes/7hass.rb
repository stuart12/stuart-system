return unless CfgHelper.activated? 'homeassistant'

condition_muted =
  {
    condition: 'template',
    value_template: Hass.all_snapcast_clients_muted,
  }

if CfgHelper.config(%w[homeassistant keyboard])
  ((1..9).to_a + %w[Backspace Enter Dot]).map do |key| # /usr/include/linux/input-event-codes.h
    KeyCodes.automation_for_key(
      'Key',
      key,
      [
        { service: 'mqtt.publish',
          data: {
            topic: 'keyboard',
            payload: "key #{key.to_s.downcase}",
          } },
      ],
    )
  end
end

if CfgHelper.activated? 'snapclient'
  Hass.automation_general(
    'Unmute local snapcast if all muted',
    trigger: (1..9).flat_map { |key| Hass.trigger_for_key(key) },
    action: {
      service: 'media_player.volume_mute',
      data: {
        entity_id: "media_player.snapcast_client_#{node.name}",
        is_volume_muted: false,
      },
    },
    condition: condition_muted,
  )

  hosts = CfgHelper.config['networking']['hosts'].keys
  # FIXME: replace with mqtt message to mute snapcast_client unless node == payload
  Hass.automation_for_key(
    'Other Amps Off',
    'Slash',
    hosts.reject { |v| v == node.name }.sort.map do |other|
      { service: 'media_player.volume_mute',
        data: {
          entity_id: "media_player.snapcast_client_#{other}",
          is_volume_muted: true,
        } }
    end,
  )

  Hass.automation_for_key(
    'Local Amp Off',
    'Asterisk',
    [
      { service: 'media_player.volume_mute',
        data: {
          entity_id: "media_player.snapcast_client_#{node.name}",
          is_volume_muted: true,
        } },
    ],
  )

  Hass.automation(
    'Reset Volume',
    [
      { platform: 'homeassistant',
        event: 'start' },
      { platform: 'template',
        value_template: "{{ is_state_attr('media_player.snapcast_client_#{node.name}', 'is_volume_muted', true) }}",
        for: 30 },
    ],
    service: 'script.reset_local_volume',
  )
end

if CfgHelper.config.dig('homeassistant', 'z-wave')
  Hass.automation(
    'Publish VMC Power',
    { platform: 'state',
      entity_id: 'sensor.qubino_goap_zmnhadx_flush_1_relay_power' },
    service: 'mqtt.publish',
    data: {
      topic: 'home/vmc/power',
      payload_template: "{{ states('sensor.qubino_goap_zmnhadx_flush_1_relay_power') }}",
    },
  )
end

trusted_networks = {
  type: 'trusted_networks',
  allow_bypass_login: true,
  trusted_networks: [
    '127.0.0.1',
    '::1',
  ],
}

Hass.media_player(
  'snapcast',
  platform: 'snapcast',
  host: CfgHelper.workstation,
)

keyboard_remote = [
  'HID 0911:2188',
  'ORTEK USB Keyboard Hub',
  'SEMICO USB Keyboard',
  'USB Keyboard',
].sort.map do |n|
  { device_name: n,
    type: 'key_down' }
end

CfgHelper.set_config['homeassistant'].tap do |hass|
  hass['configuration'].tap do |configuration|
    configuration['homeassistant'].tap do |homeassistant|
      homeassistant['name'] = CfgHelper.config['networking']['hostname']
      homeassistant['latitude'] = 48.839548
      homeassistant['longitude'] = 2.395671
      homeassistant['elevation'] = 36
      homeassistant['unit_system'] = 'metric'
      homeassistant['time_zone'] = CfgHelper.config['timezone']['name']
      homeassistant['auth_providers'] = [trusted_networks]
    end
    configuration['frontend'] = nil
    configuration['config'] = nil
    configuration['mqtt'].tap do |mqtt|
      mqtt['broker'] = 'bedroom'
      mqtt['client_id'] = CfgHelper.config['networking']['hostname']
      mqtt['protocol'] = '3.1.1'
    end
    configuration['logger'].tap do |logger|
      logger['default'] = 'warn' # https://home-assistant.io/docs/mqtt/logging/
      logger['logs'].tap do |logs|
        logs['homeassistant.components.shell_command'] = 'debug'
        logs['homeassistant.components.mqtt'] = 'debug'
        logs['homeassistant.setup'] = 'info' # log during boot
        logs['homeassistant.util.package'] = 'info' # log during boot
        logs['homeassistant.components.discovery'] = 'info' # log during boot
        logs['homeassistant.loader'] = 'info' # log during boot
      end
    end
    configuration['keyboard_remote'] = keyboard_remote
  end
end

Hass.script(
  'restart',
  { service: 'homeassistant.restart' },
  alias: 'Restart Home Assistant',
)
