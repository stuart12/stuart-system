return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '0097b564-4a3f-4e9f-8d33-be9f2ba5ffce'

CfgHelper.set_config['networking']['hostname'] = 'bedroom'

CfgHelper.set_config['boot']['config']['leds'] = false

CfgHelper.set_config['delcom-clock']['activate'] = true
CfgHelper.set_config['snapclient']['activate'] = true
CfgHelper.set_config['wifi']['activate'] = false
CfgHelper.set_config['i2c']['activate'] = true
CfgHelper.set_config['mqtt']['activate'] = true

calendar = [
  { platform: 'caldav',
    username: 'holidays',
    password: CfgHelper.secrets['homeassistant']['holidays_password'],
    url: CfgHelper.secrets['homeassistant']['holidays_url'],
    custom_calendars: [
      { name: 'OffWork',
        calendar: 'days off work (Stuart)',
        search: '.*' },
    ] },
]

Hass.script(
  'buzz_phone', [
    { service: 'shell_command.buzz_phone',
      data: {
        args: CfgHelper.secrets['homeassistant']['buzz_phone'],
      } },
  ]
)

Hass.script(
  'toggle_clock', [
    { service_template: "switch.turn_{% if is_state('switch.delcom_clock', 'off') %}on{% else %}off{% endif %}",
      entity_id: 'switch.delcom_clock' },
  ]
)

Hass.script(
  'toggle_bedside_red', [
    { service_template: "script.bedside_{% if is_state('light.bedroom', 'off') %}red{% else %}off{% endif %}" },
  ]
)

Hass.script(
  'toggle_bedside_white', [
    { service_template: "script.bedside_{% if is_state('light.bedroom', 'off') %}white{% else %}off{% endif %}" },
  ]
)

Hass.script(
  'bedside_red', [
    { service: 'light.turn_on',
      entity_id: 'light.bedroom',
      data: {
        color_name: 'red',
        brightness_pct: 100,
      } },
  ]
)

Hass.script(
  'bedside_white', [
    { service: 'light.turn_on',
      entity_id: 'light.bedroom',
      data_template: {
        color_name: "{% if is_state('calendar.days_off_work_stuart_offwork', 'on') %}green{% else %}white{% endif %}",
        brightness_pct: 100,
      } },
    { delay: '00:00:02' },
    { service: 'light.turn_on',
      entity_id: 'light.bedroom',
      data: {
        color_name: 'white',
        brightness_pct: 100,
      } },
  ]
)

Hass.script(
  'bedside_off', [
    { service: 'light.turn_off',
      entity_id: 'light.bedroom' },
  ]
)

Hass.shell_command(
  set_volume_to_slider: 'amixer -q set Digital {{ states.input_number.volume.state }}%',
  swap: 'delcom-control --swap &',
  alarm_stop: 'alarm-stop &',
  blink: 'delcom-control --blink &',
  led_on: 'delcom-control --on &',
  buzz_phone: 'buzz_phone --ring_time 10 {{ args }}',
)

Hass.sensor(
  'amp2',
  'command_line',
  command: 'amixer get Digital | sed -ne "/Front Left/s/.* \[\([0-9]*\)%.*/\1/p"',
  unit_of_measurement: '%',
  scan_interval: 59,
)

Hass.automation(
  'Publish Is Holiday State',
  [
    { platform: 'state',
      entity_id: 'calendar.days_off_work_stuart_offwork' },
    { platform: 'homeassistant',
      event: 'start' },
  ],
  [
    { service: 'mqtt.publish',
      data_template: {
        retain: true,
        topic: 'states/is_holiday',
        payload: "{{ states('calendar.days_off_work_stuart_offwork') }}",
      } },
  ],
)
Hass.automation_for_key(
  'Toggle LED red',
  'Enter',
  service: 'script.toggle_bedside_red',
)
{ 'Minus': '-', 'Plus': '+' }.each do |tag, op|
  Hass.automation_for_key(
    'Volume',
    tag,
    [
      { service: 'media_player.volume_mute',
        data: {
          entity_id: "media_player.snapcast_client_#{node.name}",
          is_volume_muted: false,
        } },
      { service: 'input_number.set_value',
        data_template: {
          entity_id: 'input_number.volume',
          value: "{{ states('input_number.volume') | int #{op} 1 }}",
        } },
    ],
  )
end
Hass.automation_for_key(
  'Toggle LED Clock',
  '0',
  service: 'script.toggle_clock',
)
Hass.automation_for_key(
  'Toggle LED White',
  'Dot',
  service: 'script.toggle_bedside_white',
)

Hass.automation(
  'Adjust Volume to Slider',
  { platform: 'state',
    entity_id: 'input_number.volume' },
  service: 'shell_command.set_volume_to_slider',
)
Hass.automation(
  'Adjust Slider to Volume',
  { platform: 'state',
    entity_id: 'sensor.amp2' },
  service: 'input_number.set_value',
  data_template: {
    entity_id: 'input_number.volume',
    value: "{{ states('sensor.amp2') }}",
  },
)
work_day = {
  condition: 'and',
  conditions: [
    { condition: 'state',
      entity_id: 'calendar.days_off_work_stuart_offwork',
      state: 'off' },
    { condition: 'time',
      weekday: %w[
        mon
        tue
        wed
        thu
        fri
      ] },
    { condition: 'template',
      value_template: '{{ is_state("switch.delcom_clock", "off") }}' },
  ],
}
Hass.automation_general(
  'Wakeup',
  trigger: {
    platform: 'time',
    at: CfgHelper.secrets['homeassistant']['alarm_time'],
  },
  condition: work_day,
  action: [
    { service: 'switch.turn_on',
      entity_id: 'switch.delcom_clock' },
    { delay: '00:00:10' },
    { service: 'script.bedside_white' },
    { service: 'mqtt.publish',
      data: {
        topic: 'message',
        payload: 'amplifier living on',
      } },
    { delay: '00:00:10' },
    { service: 'input_number.set_value',
      data_template: {
        entity_id: 'input_number.volume',
        value: 56,
      } },
    { service: 'mqtt.publish',
      data: {
        topic: 'radio',
        payload: 'France Culture',
      } },
    { service: 'switch.turn_on',
      entity_id: 'switch.amplifier' },
    { service: 'mqtt.publish',
      data: {
        topic: 'message',
        payload: 'living volume up',
      } },
    { delay: '00:00:20' },
    { service: 'input_number.set_value',
      data_template: {
        entity_id: 'input_number.volume',
        value: 70,
      } },
    { delay: '00:00:30' },
    { service: 'mqtt.publish',
      data: {
        topic: 'message',
        payload: 'living volume up',
      } },
    { service: 'script.telephone_awake' },
    { service: 'script.buzz_phone' },
    { delay: '01:00:00' },
    { service: 'mqtt.publish',
      data: {
        topic: 'message',
        payload: 'amps off',
      } },
    { service: 'script.bedside_off' },
    { delay: '00:02:11' }, # 00:01:11 was not enough
    { service: 'script.bedside_off' },
  ],
)

Hass.automation_for_key(
  'Sleep',
  'Backspace',
  [
    { service: 'script.telephone_sleep' },
    { service: 'switch.turn_off',
      entity_id: 'switch.delcom_clock' },
    { service: 'mqtt.publish',
      data: {
        topic: 'message',
        payload: 'amps off',
      } },
  ],
)

if 1 == 3
  { Down: '-', Up: '+' }.each do |tag, op|
    Hass.automation(
      "MQTT Volume #{tag}",
      { platform: 'mqtt',
        topic: 'message',
        payload: "bedroom volume #{tag.lowercase}" },
      [
        { service: 'switch.turn_on',
          entity_id: 'switch.amplifier' },
        { service: 'input_number.set_value',
          data_template: {
            entity_id: 'input_number.volume',
            value: "{{ states('input_number.volume') | int #{op} 1 }}",
          } },
      ],
    )
  end
end

Hass.switch(
  'command_line',
  'amplifier',
  command_on: 'amixer -q set Digital unmute',
  command_off: 'amixer -q set Digital mute',
  command_state: 'amixer get Digital | fgrep -q "[on]"',
  friendly_name: 'Amplifier',
)
Hass.switch(
  'command_line',
  'delcom_clock',
  command_on: 'delcom-control --on; sleep 1',
  command_off: 'delcom-control --off; sleep 1',
  command_state: 'cat /sys/bus/usb/drivers/usbsevseg/*/text',
  value_template: '{{ value != "\0" }}',
  friendly_name: 'Bedroom Led',
)

keyboard_remote = ['SEMICO USB Keyboard', 'ORTEK USB Keyboard Hub'].map do |n|
  { device_name: n,
    type: 'key_down' }
end

light = [
  { platform: 'blinksticklight',
    serial: 'BS015348-3.0',
    name: 'bedroom' },
]

CfgHelper.set_config['homeassistant'].tap do |homeassistant|
  homeassistant['activate'] = true
  homeassistant['blinksticklight'] = true
  homeassistant['keyboard'] = true
  homeassistant['audio'] = true
  homeassistant['configuration'].tap do |configuration|
    configuration['keyboard_remote'] = keyboard_remote
    configuration['light'] = light
    configuration['calendar'] = calendar
    configuration['recorder'].tap do |recorder|
      recorder['purge_interval'] = 1
      recorder['purge_keep_days'] = 3
    end
    configuration['input_number'].tap do |input_number|
      input_number['volume'].tap do |volume|
        volume['min'] = 50
        volume['initial'] = 70
        volume['max'] = 100
        volume['step'] = 1
      end
    end
  end
end
