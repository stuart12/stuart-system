ck = 'stuart'

activated = node[ck]['config']['wifi']['activate']

%w[wpasupplicant iw].each do |pkg|
  package pkg do
    action activated ? :upgrade : :remove
  end
end

execute 'restart-wifi' do
  command 'wpa_cli -i wlan0 reconfigure'
  action :nothing
end

template '/etc/wpa_supplicant/wpa_supplicant.conf' do
  source 'wpa_supplicant.conf.erb'
  variables(
    networks: { node['secrets']['wifi']['ssid'] => node['secrets']['wifi']['psk'] },
  )
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
