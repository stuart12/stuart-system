# FIXME: need to add password

ck = 'stuart'

mqtt = node[ck]['config']['mqtt']

%w[mosquitto-clients mosquitto].each do |pkg|
  package pkg do
    action mqtt ? :upgrade : :remove
  end
end

return unless mqtt

# execute 'mosquitto_passwd' do
#  command ['mosquitto_passwd', '-b',
# node[ck]['config']['mqtt']['user']
#
# execute 'restart-wifi' do
#   command 'wpa_cli -i wlan0 reconfigure'
#   action :nothing
# end
#
# template '/etc/wpa_supplicant/wpa_supplicant.conf' do
#   source 'wpa_supplicant.conf.erb'
#   variables(
#     networks: { node['secrets']['wifi']['ssid'] => node['secrets']['wifi']['psk'] },
#   )
#   user 'root'
#   group 'adm'
#   mode 0o640
#   notifies :run, 'execute[restart-wifi]'
# end
#
# execute 'rfkill unblock wlan' do
#   only_if { ::File.read('/sys/class/net/wlan0/phy80211/rfkill0/soft').chomp == '1' }
# end
