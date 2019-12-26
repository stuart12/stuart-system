default[CfgHelper.base]['config']['wifi']['wpa_cfg'] = '/etc/wpa_supplicant/wpa_supplicant.conf'
default[CfgHelper.base]['config']['wifi']['interface'] = 'wlan0'

CfgHelper.add_package 'wpasupplicant'
CfgHelper.add_package 'iw'

CfgHelper.systemd_unit(
  'wpa_supplicant.service',
  Unit: {
    Description: 'WPA supplicant',
    Before: 'network.target',
    Wants: 'network.target',
  },
  Service: {
    ExecStart: [
      '/sbin/wpa_supplicant -s',
      "-c#{CfgHelper.config['wifi']['wpa_cfg']}",
      "-i#{CfgHelper.config['wifi']['interface']}",
    ].join(' '),
  },
  Install: {
    WantedBy: 'multi-user.target',
  },
)
