return unless CfgHelper.activated? 'wifi'

package %w[
  wpasupplicant
  iw
]

# I could not get wpa_cli v2.8-devel to talk dBus to wpa_supplicant
# so use a simplistic method that will only work with 1 wifi interface.
#
# execute 'restart-wifi' do
#   command "wpa_cli -i #{CfgHelper.config['wifi']['interface']} reconfigure"
#   action :nothing
# end

systemd_unit 'wpa_supplicant.service' do
  action :nothing
end

template CfgHelper.config['wifi']['wpa_cfg'] do
  variables(
    networks: { node['secrets']['wifi']['ssid'] => node['secrets']['wifi']['psk'] },
  )
  user 'root'
  group 'adm'
  mode 0o640
  # notifies(:run, 'execute[restart-wifi]') if activated
  notifies(:restart, 'systemd_unit[wpa_supplicant.service]', :delayed)
end

execute 'rfkill unblock wlan' do
  only_if 'rfkill list wifi | grep yes$'
end

return if 0.zero?

systemd_unit 'wicd.service' do
  action :nothing
end

template '/etc/wicd/manager-settings.conf' do
  source 'ini.erb'
  variables(
    sections: { Settings: { wired_interface: 'None' } },
    comment: ';',
  )
  owner 'root'
  notifies(:restart, 'systemd_unit[wicd.service]', :delayed)
end
