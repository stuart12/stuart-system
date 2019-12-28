CfgHelper.set_config['wifi'].tap do |cfg|
  cfg['wpa_cfg'] = '/etc/wpa_supplicant/wpa_supplicant.conf'
  cfg['interface'] = 'wlan0'
end
CfgHelper.set_config['systemd']['units']['wpa_supplicant.service'].tap do |srv|
  srv['what'] = 'wifi'
  srv['content'].tap do |content|
    content['Unit'].tap do |unit|
      unit['Description'] = 'WPA supplicant maintained by Chef'
      unit['Before'] = 'network.target'
      unit['Wants'] = 'network.target'
    end
    content['Service']['ExecStart'] = [
      '/sbin/wpa_supplicant -s',
      "-c#{CfgHelper.config['wifi']['wpa_cfg']}",
      "-i#{CfgHelper.config['wifi']['interface']}",
    ].join(' ')
    content['Install']['WantedBy'] = 'multi-user.target'
  end
end
