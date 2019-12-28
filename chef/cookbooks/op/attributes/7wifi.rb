CfgHelper.set_config['wifi'].tap do |cfg|
  cfg['wpa_cfg'] = '/etc/wpa_supplicant/wpa_supplicant.conf'
  cfg['interface'] = 'wlan0'

  cfg['systemd'].tap do |systemd|
    systemd['Unit'].tap do |unit|
      unit['Description'] = 'WPA supplicant maintained by Chef'
      unit['Before'] = 'network.target'
      unit['Wants'] = 'network.target'
    end
    systemd['Service']['ExecStart'] = [
      '/sbin/wpa_supplicant -s',
      "-c#{CfgHelper.config['wifi']['wpa_cfg']}",
      "-i#{CfgHelper.config['wifi']['interface']}",
    ].join(' ')
    systemd['Install']['WantedBy'] = 'multi-user.target'
  end
end
