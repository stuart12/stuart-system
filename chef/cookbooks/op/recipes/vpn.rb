return unless CfgHelper.activated? 'vpn'

package 'vpnc' do
  action :upgrade
end

def hash_to_2dim_array(h, c = [])
  if h.is_a?(Hash)
    h.flat_map do |k, v|
      hash_to_2dim_array(v, c + [k])
    end
  else
    [c + [h]]
  end
end
# hash_to_2dim_array(1 => 4, 5 => { 0 => 6, 2 => 3 }, 12 => { 5 => 3, 13 => { 14 => 15 } })

lines = hash_to_2dim_array(
  IPSec: node['secrets']['criteo']['prod-vpn'],
  Xauth: node['secrets']['criteo']['ldap'],
  No: 'Detach',
)
template '/etc/vpnc/criteo-prod.conf' do
  variables(
    lines: lines,
  )
  source 'lines.erb'
  mode 0o640
  owner 'root'
  group 'adm'
  sensitive true
end
