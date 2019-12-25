ck = 'stuart'

return unless platform? 'raspbian'

unless node[ck].dig('config', 'wifi', 'activate')
  # https://raspberrypi.stackexchange.com/questions/100543/how-to-disable-wifi-in-raspberry-pi-4
  default[ck]['config']['boot']['config']['dtoverlay']['disable-wifi'] = 'pi4'
  default[ck]['config']['boot']['config']['dtoverlay']['pi3-disable-wifi'] = 'pi3'
end
default[ck]['config']['boot']['config']['dtoverlay']['pi3-disable-bt'] = 'pi3'
default[ck]['config']['boot']['config']['dtoverlay']['disable-bt'] = 'pi4' # FIXME
default[ck]['config']['boot']['config']['dtoverlay']['hifiberry-dacplus'] = false

unless default[ck]['config']['boot']['config']['leds']
  {
    'eth_led0' => 14,
    'eth_led1' => 14,
    'pwr_led_activelow' => 'off',
    'act_led_activelow' => 'off',
    'pwr_led_trigger' => 'none',
    'act_led_trigger' => 'none',
  }.each do |setting, value|
    default[ck]['config']['boot']['config']['dtparam'][setting] = value
  end
end

default[ck]['config']['boot']['config']['options'] = {
  'gpu_mem' => 16, # https://www.raspberrypi.org/documentation/configuration/config-txt/memory.md
  'start_x' => 0, # https://www.raspberrypi.org/documentation/configuration/config-txt/boot.md
}
