(1..9).map do |key|
  KeyCodes.automation_for_key(
    'Key',
    key,
    [
      { service: 'mqtt.publish',
        data: {
          topic: 'keyboard',
          payload: "key #{key}",
        } },
    ],
  )
end
hosts = CfgHelper.config['networking']['hosts'].keys

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

trusted_networks = {
  type: 'trusted_networks',
  allow_bypass_login: true,
  trusted_networks: [
    '127.0.0.1',
    '::1',
  ],
}
media_player = [
  { 'platform' => 'snapcast',
    'host' => 'kooka' },
]

CfgHelper.set_config['homeassistant'].tap do |hass|
  hass['configuration'].tap do |configuration|
    configuration['homeassistant'].tap do |homeassistant|
      homeassistant['latitude'] = 48.839548
      homeassistant['longitude'] = 2.395671
      homeassistant['elevation'] = 36
      homeassistant['unit_system'] = 'metric'
      homeassistant['auth_providers'] = [trusted_networks]
    end
    configuration['frontend'] = nil
    configuration['config'] = nil
    configuration['mqtt'].tap do |mqtt|
      mqtt['broker'] = 'bedroom'
      mqtt['client_id'] = CfgHelper.config['networking']['hostname']
      mqtt['protocol'] = '3.1.1'
    end
    configuration['media_player'] = media_player
    configuration['logger'].tap do |logger|
      logger['default'] = 'warn' # https://home-assistant.io/docs/mqtt/logging/
      logger['logs'].tap do |logs|
        logs['homeassistant.components.mqtt'] = 'debug'
        logs['homeassistant.components.calendar'] = 'debug'
      end
    end
  end
end
