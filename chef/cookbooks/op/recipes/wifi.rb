# I could not get wpa_cli v2.8-devel to talk dBus to wpa_supplicant
# so use a simplistic method that will only work with 1 wifi interface.

activated = CfgHelper.activated? 'wifi'

%w[
  wpasupplicant
  iw
].each do |pkg|
  package pkg do
    action activated ? :upgrade : :remove
  end
end

# execute 'restart-wifi' do
#   command "wpa_cli -i #{CfgHelper.config['wifi']['interface']} reconfigure"
#   action :nothing
# end

template CfgHelper.config['wifi']['wpa_cfg'] do
  if activated
    variables(
      networks: { node['secrets']['wifi']['ssid'] => node['secrets']['wifi']['psk'] },
    )
  end
  user 'root'
  group 'adm'
  mode 0o640
  # notifies(:run, 'execute[restart-wifi]') if activated
  notifies(:restart, 'systemd_unit[wpa_supplicant.service]', :delayed) if activated
  action activated ? :create : :delete
end

execute 'rfkill unblock wlan' do
  only_if { activated }
  only_if { ::File.read('/sys/class/net/wlan0/phy80211/rfkill0/soft').chomp == '1' }
end

systemd_unit 'wpa_supplicant.service' do
  content CfgHelper.config['wifi']['systemd']
  action activated ? :restart : %i[stop delete]
end
