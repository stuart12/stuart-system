
all_muted = [
  "{% for i in states.media_player if i.state == 'on' and is_state_attr('media_player.' + i.name, 'is_volume_muted', False) %}",
  'f',
  '{% else %}',
  'true',
  '{% endfor %}',
].join

condition_muted =
  {
    condition: 'template',
    value_template: all_muted,
  }

((1..9).to_a + %w[Enter Dot]).map do |key|
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
(1..9).map do |key|
  Hass.automation_for_key(
    'Play if silent',
    key,
    { service: 'media_player.volume_mute',
      data: {
        entity_id: "media_player.snapcast_client_#{node.name}",
        is_volume_muted: false,
      } },
    condition: condition_muted,
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

%w[sleep awake].each do |state|
  Hass.script(
    "telephone_#{state}", [
      { service: 'mqtt.publish',
        data: {
          topic: 'telephone',
          payload: state,
        } },
    ]
  )
end

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
