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

  hosts = CfgHelper.config(%w[networking hosts]).keys
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

  Hass.automation(
    'Local Amp Off',
    [
      *Hass.trigger_for_key('Asterisk'),
      Hass.snapcast_groups_playing(false).merge(for: 90),
      { platform: 'homeassistant',
        event: 'start' },
    ],
    service: 'media_player.volume_mute',
    data: {
      entity_id: "media_player.snapcast_client_#{node.name}",
      is_volume_muted: true,
    },
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

Hass.binary_template_sensor( # https://www.home-assistant.io/integrations/binary_sensor.template/
  Hass.snapcast_playing_entity_id.split('.').last,
  %({%
for i in states.media_player if i.name[0:15] == 'snapcast_group_' and i.state == 'idle'
%}f{%
else
%}true{%
endfor
%}).tr("\n", ' '),
  friendly_name: 'Snapcast',
)

Hass.automation(
  'update playing',
  { platform: 'time_pattern',
    seconds: '/2' },
  service: 'homeassistant.update_entity',
  data: {
    entity_id: [
      Hass.snapcast_playing_entity_id,
    ],
  },
)

if CfgHelper.config(%w[homeassistant])['z-wave']
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
  ].sort,
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

CfgHelper.attributes(
  %w[homeassistant configuration],
  homeassistant: {
    name: CfgHelper.config(%w[networking hostname]),
    latitude: CfgHelper.secret(%w[homeassistant latitude]),
    longitude: CfgHelper.secret(%w[homeassistant longitude]),
    elevation: CfgHelper.secret(%w[homeassistant elevation]),
    unit_system: 'metric',
    time_zone: CfgHelper.config(%w[timezone name]),
    auth_providers: trusted_networks,
  },
  frontend: nil,
  config: nil,
  mqtt: {
    broker: 'bedroom',
    client_id: CfgHelper.config(%w[networking hostname]),
    protocol: '3.1.1',
  },
  logger: {
    default: 'warn', # https://home-assistant.io/docs/mqtt/logging/
    logs: {
      'homeassistant.components.shell_command': 'debug',
      'homeassistant.components.mqtt': 'info', # debug to see all messages
      'homeassistant.setup': 'info', # log during boot
      'homeassistant.util.package': 'info', # log during boot
      'homeassistant.components.discovery': 'info', # log during boot
      'homeassistant.loader': 'info', # log during boot
    },
  },
  keyboard_remote: keyboard_remote,
)

Hass.script(
  'restart',
  { service: 'homeassistant.restart' },
  alias: 'Restart Home Assistant',
)

%w[Up Down].each do |operation|
  Hass.script(
    "Living Volume #{operation}",
    Hass.living_volume(operation),
  )
end
