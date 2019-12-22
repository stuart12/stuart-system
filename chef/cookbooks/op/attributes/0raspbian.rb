ck = 'stuart'

return unless platform? 'raspbian'

# rubocop:disable LineLength
default[ck]['config']['sshd']['ssh_keys'] =
  {
    'pi' => [
      'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA34JVpS1wfN99SxuuwKQBKgUxOu6JmJq1ANO/A+/Iypabn3AbEyeXUCJPQe+VY/p8Opk01Ywm6h/vAQgHILGVDsBR0EQ4Ku444PXACBfdLkShclOR3LIUq3BDaZq1LJTryPQhqhnTBhLUvUvQy4RtLB8grKIEMcyGRcAr+1Uo4Bf+VU2VdFbW+dJb45jM66pd20/tmhBTFwHee8BO32nJKYHXdmgHOIci29bzPBJGnD0M3HFzbh9qgCLuTCWx9/77TogO28TPhoVP7BoOAji4YJxxzT/0CMeAoTRQaFB2aMAo56Ix+Pxnx2GYDq83NUWjjVBnTovlxIXxK7VcSlt7WQ== stuart@kooka',
    ],
  }
# rubocop:enable LineLength

default[ck]['config']['sshd']['activate'] = true
default[ck]['config']['firewall']['activate'] = true
default[ck]['config']['packages']['install']['ruby-shadow'] = true # Chef's password resource

# https://raspberrypi.stackexchange.com/questions/100543/how-to-disable-wifi-in-raspberry-pi-4
default[ck]['config']['boot']['config']['dtoverlay']['disable-bt'] = 'pi4' # FIXME
default[ck]['config']['boot']['config']['dtoverlay']['disable-wifi'] = 'pi4'
default[ck]['config']['boot']['config']['dtoverlay']['pi3-disable-bt'] = 'pi3'
default[ck]['config']['boot']['config']['dtoverlay']['pi3-disable-wifi'] = 'pi3'
default[ck]['config']['boot']['config']['dtoverlay']['hifiberry-dacplus'] = false

default[ck]['config']['boot']['config']['dtparam'] = {
  'eth_led0' => 14,
  'eth_led1' => 14,
  'pwr_led_activelow' => 'off',
  'act_led_activelow' => 'off',
  'pwr_led_trigger' => 'none',
  'act_led_trigger' => 'none',
}

default[ck]['config']['boot']['config']['options'] = {
  'gpu_mem' => 16, # https://www.raspberrypi.org/documentation/configuration/config-txt/memory.md
  'start_x' => 0, # https://www.raspberrypi.org/documentation/configuration/config-txt/boot.md
}
