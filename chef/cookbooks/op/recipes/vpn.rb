return unless CfgHelper.activated? 'vpn'

package 'vpnc' do
  action :upgrade
end

def hash_to_2dim_array(remaining, path = [])
  if remaining.is_a?(Hash)
    remaining.flat_map do |k, v|
      hash_to_2dim_array(v, path + [k])
    end
  else
    [path + [remaining]]
  end
end
# hash_to_2dim_array(1 => 4, 5 => { 0 => 6, 2 => 3 }, 12 => { 5 => 3, 13 => { 14 => 15 } })

lines = hash_to_2dim_array(
  IPSec: node['secrets']['criteo']['prod-vpn'],
  Xauth: node['secrets']['criteo']['ldap'],
  No: 'Detach',
)
vpn = 'criteo-prod'
template "/etc/vpnc/#{vpn}.conf" do
  variables(
    lines: lines,
  )
  source 'lines.erb'
  mode 0o640
  owner 'root'
  group 'adm'
  sensitive true
end

sudo vpn do
  commands ["/usr/sbin/vpnc #{vpn}"]
  users CfgHelper.users.keys
  nopasswd true
end
