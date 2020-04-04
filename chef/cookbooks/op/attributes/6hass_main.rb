return unless CfgHelper.activated? 'hass_main'

Hass.attributes(%w[configuration history], nil)
Hass.attributes(%w[configuration logbook], nil)

radios = {
  '1': 'RFI Monde',
  '2': 'France Culture',
  '3': 'BBC World Service (AAC)',
  '4': 'BBC Radio 4',
  '7': 'Public Radio International PRI 24 Hour Stream',
  '8': 'France Info',
  '9': 'Radio Paradise (320k)',
}

CfgHelper.attributes(
  %w[homeassistant includes input_select contents radio_station],
  name: 'Radio Station',
  options:
  (
    radios.values +
    [
      'RFI Monde',
      'RFI Afrique',
      'France Culture',
      'ABC Radio National MP3',
      'France Info',
      'France Inter',
      'BBC World Service (AAC)',
      'BBC Radio 4',
      'Public Radio International PRI 24 Hour Stream',
      'Audiophile Classical',
      'FIP',
      'Chérie FM',
      'Radio Tram',
      'Radio 9090 90.9',
      'Nogoum FM 100.6',
      '181.FM - Vocal Jazz',
      '#1 Jazz Radio',
      '.977 Smooth Jazz',
    ]
  ).sort.uniq + ['None'],
  initial: 'None',
  icon: 'mdi:radio',
)

Hass.media_player(
  'mpd',
  platform: 'mpd',
  host: 'localhost',
  password: CfgHelper.secret(%w[mpd password]),
)

{
  from: { volume: 0.8, alias: 'Set Volume For Other Than BBC' },
  to: { volume: 1.0, alias: 'Increase Volume For BBC' },
}
  .each do |state, cfg|
  Hass.automation(
    cfg[:alias],
    { platform: 'state',
      entity_id: 'sensor.mpd_media_title',
      state => 'bbc_world_service.m3u8' },
    { service: 'media_player.volume_set',
      data_template: {
        entity_id: 'media_player.mpd',
        volume_level: cfg[:volume],
      } },
  )
end

spotify_entity = "media_player.spotify_#{CfgHelper.secret(%w[spotify user])}"
spotify_source = CfgHelper.secret(%w[spotify device])

Hass.script(
  'play_spotify',
  [
    { service: 'media_player.select_source',
      data: {
        entity_id: spotify_entity,
        source: spotify_source,
      } },
    { wait_template: "{{ is_state_attr('media_player.spotify_stewart750', 'source', '47spots') }}",
      timeout: '00:01:00' }, # https://community.home-assistant.io/t/spotify-404-from-api-from-time-to-time/61362/4
    { service: 'media_player.media_play',
      data: {
        entity_id: spotify_entity,
      } },
  ],
  alias: 'Play Spotify',
)

CfgHelper.attributes(
  %w[homeassistant includes spotify],
  secret: true,
  contents: {
    client_id: CfgHelper.secret(%w[spotify id]),
    client_secret: CfgHelper.secret(%w[spotify secret]),
  },
)
spotify_max_volume = CfgHelper.attributes(%w[spotify volume maximum], 0.8)

Hass.automation(
  'Cap Spotify Volume',
  { platform: 'numeric_state',
    entity_id: spotify_entity,
    value_template: '{{ state.attributes.volume_level }}',
    above: spotify_max_volume },
  { service: 'media_player.volume_set',
    data_template: {
      entity_id: spotify_entity,
      volume_level: spotify_max_volume,
    } },
)
Hass.automation(
  'Clear radio choice on MPD stop',
  { platform: 'state',
    entity_id: 'media_player.mpd',
    to: 'paused' },
  { service: 'input_select.select_option',
    data: { # https://home-assistant.io/components/input_select/
      entity_id: 'input_select.radio_station',
      option: 'None',
    } },
)

Hass.script(
  'telephone_awake',
  { service: 'shell_command.telephone_mode',
    data: {
      value: '--off',
    } },
)

Hass.automation(
  'Wake telephone on MPD Start',
  { platform: 'state',
    entity_id: 'media_player.mpd',
    to: 'playing' },
  { service: 'script.telephone_awake' },
)

spotify_state_attr = "{{ is_state_attr('#{spotify_entity}', 'source', '#{spotify_source}') }}"
def pause(what)
  { service: 'media_player.media_pause',
    data: {
      entity_id: what,
    } }
end

def on_other_start(what)
  [
    pause(what),
    { service: 'script.telephone_awake' },
  ]
end
Hass.automation(
  'Stop Spotify on MPD Start',
  { platform: 'state',
    entity_id: 'media_player.mpd',
    to: 'playing' },
  { condition: 'template',
    value_template: spotify_state_attr },
  pause(spotify_entity),
)

Hass.automation(
  'Pause MPD on Spotify set to 47spots',
  { platform: 'template',
    value_template: spotify_state_attr },
  { condition: 'state',
    entity_id: spotify_entity,
    state: 'playing' },
  on_other_start('media_player.mpd'),
)

Hass.automation(
  'Pause MPD on Spotify Start to 47spots',
  { platform: 'state',
    entity_id: spotify_entity,
    to: 'playing' },
  { condition: 'template',
    value_template: spotify_state_attr },
  on_other_start('media_player.mpd'),
)

sleep_automation = 'telephone_sleep'
Hass.automation(
  sleep_automation,
  { platform: 'mqtt',
    topic: 'telephone',
    payload: 'sleep' },
  [{ service: 'automation.turn_off',
     entity_id: "automation.#{sleep_automation}" },
   { service: 'shell_command.telephone_mode',
     data: {
       value: '--on',
     } },
   { delay: {
     minutes: 1,
   } },
   { service: 'automation.turn_on',
     entity_id: "automation.#{sleep_automation}" }],
)

awake_automation = 'telephone_awake'
Hass.automation(
  awake_automation,
  { platform: 'mqtt',
    topic: 'telephone',
    payload: 'awake' },
  [ # https://community.home-assistant.io/t/limit-automation-triggering/14915
    { service: 'automation.turn_off',
      entity_id: "automation.#{awake_automation}" },
    { service: 'script.telephone_awake' },
    { service: 'automation.turn_on',
      entity_id: "automation.#{awake_automation}" },
  ],
)

def mqtt_key(key)
  {
    platform: 'mqtt',
    topic: 'keyboard',
    payload: "key #{key}",
  }
end

Hass.automation(
  'key backspace - next track',
  key('backspace'),
  { service: 'media_player.media_next_track' },
)

radios.each do |key, radio|
  Hass.automation(
    "key #{key} - #{radio}",
    mqtt_key(key),
    { service: 'shell_command.radio_info',
      data: {
        value: radio,
      } },
  )
end

{
  '5': 'shell_command.playnewestpod',
  '6': 'script.play_spotify',
}.each do |key, service|
  Hass.automation(
    "key #{key} - #{service.split('.').last}",
    mqtt_key(key),
    { service: service },
  )
end

Hass.script(
  'playnewestpod',
  { service: 'shell_command.playnewestpod' },
  alias: 'Play Newest Podcast',
)

entities_state = { 'media_player.mpd' => 'off', spotify_entity => 'idle' }
delay = { for: 10 }
Hass.automation(
  'shutdown snapcast',
  entities_state.flat_map do |entity, state|
    ['paused', state].map do |state2|
      {
        platform: 'state',
        entity_id: entity,
        to: state2,
      }.merge(delay)
    end
  end,
  {
    condition: 'and',
    conditions: entities_state.map do |entity, state|
                  {
                    condition: 'or',
                    conditions: ['paused', state].map do |state2|
                      {
                        condition: 'state',
                        entity_id: entity,
                        state: state2,
                      }.merge(delay)
                    end,
                  }
                end,
  },
  [
    { service: 'media_player.volume_mute',
      data: {
        is_volume_muted: true,
        entity_id: 'media_player.snapcast_client_bedroom',
      } }, # FIXME
    { service: 'media_player.volume_mute',
      data: {
        is_volume_muted: true,
        entity_id: 'media_player.snapcast_client_entrance',
      } },
    { service: 'media_player.volume_mute',
      data: {
        is_volume_muted: true,
        entity_id: 'media_player.snapcast_client_bathroom',
      } },
  ],
)

Hass.automation( # https://home-assistant.io/components/input_select/
  'Choose From Radio List',
  { platform: 'state',
    entity_id: 'input_select.radio_station' },
  { service: 'shell_command.radio_info',
    data_template: {
      value: '{{ states.input_select.radio_station.state }}',
    } },
)

Hass.shell_commands(
  telephone_mode: "airplane-mode --verbose --serial #{CfgHelper.secret(%w[telephone serial])} {{ value }}",
  radio_info: 'radioinfo_mpd.py -v "{{ value }}"',
  playnewestpod: 'playnewestpod --cache $SRV/playnewestpod --config $SRV/playnewestpod',
  democracynow: 'playnewestpod --cache $SRV/playnewestpod --config $SRV/playnewestpod http://www.democracynow.org/podcast.xml',
)

Hass.binary_sensor(
  'Is Holiday',
  'mqtt',
  state_topic: 'states/is_holiday',
  payload_on: 'on',
  payload_off: 'off',
)

Hass.sensor(
  'VMC',
  'mqtt',
  state_topic: 'home/vmc/power',
  unit_of_measurement: 'W',
  icon: 'mdi:fan', # https://cdn.materialdesignicons.com/4.5.95/
)

{ '2.5' => 21_025, '3.5' => 21_035 }.each do |size, port|
  Hass.sensor(
    "#{size}″ disk",
    'tcp',
    host: 'localhost',
    port: port,
    value_template: "{{ value|regex_replace(find='\n')|regex_replace(find='.*drive state is: *')|regex_replace(find='/.*') }}",
    payload: '',
  )
end

Hass.sensor(
  'CPU Temp',
  'command_line',
  command: 'cat /sys/class/thermal/thermal_zone2/temp',
  unit_of_measurement: '°C',
  value_template: '{{ value | multiply(0.001) | round(1) }}',
)

Hass.sensor(
  'MX500',
  'tcp',
  host: 'localhost',
  port: 7635,
  payload: '',
  value_template: "{{ value.split('|')[3] | int }}",
  unit_of_measurement: '°C',
)

# https://www.home-assistant.io/integrations/sensor/
# https://www.home-assistant.io/docs/configuration/customizing-devices/
{ 'Bed Pi' => 'home/pi/temperature', 'Bedroom' => 'home/bedroom/temperature' }.each do |friendly, topic|
  name = friendly.downcase.gsub(' ', '_')
  full = "#{name}_full"
  Hass.sensor(
    full,
    'mqtt',
    state_topic: topic,
    unit_of_measurement: '°C',
    device_class: 'temperature',
    force_update: true,
    value_template: '{{ value_json | float }}',
  )
  Hass.hide('sensor', full)
  Hass.template_sensor(
    name,
    "{{ states.sensor.#{full}.state | round(1) }}",
    friendly_name: friendly,
    unit_of_measurement: '°C',
    device_class: 'temperature',
  )
end

Hass.history_graph( # https://community.home-assistant.io/t/what-will-replace-the-history-graph-after-its-deprecated-0-107-0/171863/24
  'bedroom_temperature',
  refresh: 60,
  hours_to_show: 480,
  entities: [
    'sensor.bedroom_full',
  ],
)
Hass.history_graph( # https://community.home-assistant.io/t/what-will-replace-the-history-graph-after-its-deprecated-0-107-0/171863/24
  'disk_temperature',
  refresh: 60,
  hours_to_show: 48,
  entities: [
    'sensor.cpu_temp',
    'sensor.MX500',
  ],
)

Hass.history_graph( # https://community.home-assistant.io/t/what-will-replace-the-history-graph-after-its-deprecated-0-107-0/171863/24
  'disks_states',
  name: 'Disk States',
  refresh: 60,
  hours_to_show: 48,
  entities: [
    'sensor.2_5_disk',
    'sensor.3_5_disk',
  ],
)
