activated = CfgHelper.activated? 'wifi'

execute 'restart-wifi' do
  command "wpa_cli -i #{CfgHelper.config['wifi']['interface']} reconfigure"
  action :nothing
end

template CfgHelper.config['wifi']['wpa_cfg'] do
  if activated
    variables(
      networks: { node['secrets']['wifi']['ssid'] => node['secrets']['wifi']['psk'] },
    )
  end
  user 'root'
  group 'adm'
  mode 0o640
  notifies :run, 'execute[restart-wifi]' if activated
  action activated ? :create : :delete
end

execute 'rfkill unblock wlan' do
  only_if { activated }
  only_if { ::File.read('/sys/class/net/wlan0/phy80211/rfkill0/soft').chomp == '1' }
end
