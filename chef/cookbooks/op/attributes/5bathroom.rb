return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '3442860e-35fd-41fd-b73d-30d4ccf50a8a'

CfgHelper.attributes(%w[networking hostname], 'bathroom')
CfgHelper.attributes(%w[boot config leds], false)
CfgHelper.attributes(%w[homeassistant keyboard], true)

CfgHelper.activate %w[
  homeassistant
  snapclient
  wifi
]

snap = "media_player.snapcast_client_#{node.name}"
def mute_action(state, snap)
  { service: 'media_player.volume_mute',
    data: {
      entity_id: snap,
      is_volume_muted: state,
    } }
end

{
  'Plus' => '+', 'Minus' => '-'
}.map do |key, operation|
  KeyCodes.automation_for_key(
    "Volume #{operation}",
    key,
    [
      mute_action(false, snap),
      { service: 'media_player.volume_set',
        entity_id: snap,
        data_template: {
          volume_level: "{{ state_attr('#{snap}', 'volume_level') | float #{operation} 0.1 }}",
        } },
    ],
  )
end

{
  'Numlock' => 'down', 'Tab' => 'up'
}.map do |key, operation|
  KeyCodes.automation_for_key(
    "Living Volume #{operation}",
    key,
    Hass.living_volume(operation),
  )
end

Hass.script(
  'reset_local_volume',
  service: 'media_player.volume_set',
  data: {
    entity_id: snap,
    volume_level: 0.1,
  },
)
