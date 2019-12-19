ck = 'stuart'

if platform? 'raspbian'
  default[ck]['config']['boot']['config']['dtoverlay'] = {
    'pi3-disable-bt' => true,
    'pi3-disable-wifi' => !node[ck]['config']['wifi']['activate'],
    'hifiberry-dacplus' => false,
  }
  default[ck]['config']['boot']['config']['dtparam'] = {
    'eth_led0' => 14,
    'eth_led1' => 14,
    'pwr_led_activelow' => 'off',
    'act_led_activelow' => 'off',
    'pwr_led_trigger' => 'none',
    'act_led_trigger' => 'none',
  }.merge(node[ck]['config']['i2c']['activate'] ? { 'i2c_arm' => 'on' } : {})
end

# dtparam=act_led_trigger=none
# dtparam=act_led_trigger=none
# dtparam=eth_led0=14
# dtparam=eth_led1=14
# dtparam=i2c_arm=on
# dtparam=pwr_led_activelow=off
# dtparam=pwr_led_activelow=on
# dtparam=pwr_led_trigger=none
# dtparam=pwr_led_trigger=none
# gpu_mem=16
