ck = 'stuart'
default[ck]['config']['boot']['config']['dtoverlay'] = {
  'pi3-disable-bt' => true,
  'pi3-disable-wifi' => false,
  'hifiberry-dacplus' => false,
}
default[ck]['config']['boot']['config']['dtparam'] = {
  'i2c_arm' => 'on',
  'act_led_trigger' => false,
}
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
