return unless CfgHelper.activated? 'wifi'

package 'wireless-tools' # debugging
package 'wpasupplicant' # don't lose this
package 'rfkill' # don't lose this

package %w[
  wicd
  wicd-gtk
] do
  action :purge
end

package 'network-manager'

package %w[
  network-manager-gnome
  nm-tray
] do
  action :install
  default_release 'stable' # until can remove abank
end

systemd_unit 'wpa_supplicant.service' do
  action :delete # cleanup, use default service from the package
end

wpa_cfg = CfgHelper.config['wifi']['wpa_cfg']
if wpa_cfg
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
end

execute 'rfkill unblock wlan' do
  only_if 'rfkill list wifi | grep yes$'
end
