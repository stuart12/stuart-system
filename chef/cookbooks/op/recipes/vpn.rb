return unless CfgHelper.activated? 'vpn'

paquet 'vpnc'

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

lib = CfgHelper.attributes(%w[scripts lib], '/usr/local/lib')

script = ::File.join(lib, 'vpnc-script')
iface = 'chef0'
lines = hash_to_2dim_array(
  IPSec: CfgHelper.secret(%w[work prod-vpn]),
  Xauth: CfgHelper.secret(%w[work ldap]),
  No: 'Detach',
  'Interface name': iface,
  Script: script,
)
vpn = 'prod'
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
  commands [
    "/sbin/vpnc #{vpn}",
  ]
  users CfgHelper.users.keys
  nopasswd true
end

cookbook_file script do
  source 'vpnc-script.sh'
  mode 0o744
  owner 'root'
end

template ::File.join(CfgHelper.config(%w[scripts bin]), 'criteo') do
  source 'shell_script.erb'
  action :delete # FIXME: remove
end

networkd = 'systemd-networkd.service'
systemd_unit networkd do
  action :nothing
end

resolved = 'systemd-resolved.service'
systemd_unit resolved do
  action :nothing
end

routes = CfgHelper.attributes(
  %w[dns vpn routes],
  %w[
    10.0.0.0/8
    172.16.0.0/12
    192.168.0.0/16
  ].map { |addr| [addr, true] }.to_h,
)

domains = CfgHelper.secret(%w[work internal domains]).map { |d| "~#{d}" }

network = [
  ['Match', {
    Name: iface,
  }],
  ['Network', {
    DNS: CfgHelper.secret(%w[work internal dns]).sort.join(' '),
    Domains: domains.sort.join(' '),
    DNSSEC: 'no',
  }],
  *routes.select { |_, wanted| wanted }.keys.sort.map do |addr|
    [
      'Route', {
        Destination: addr,
      }
    ]
  end,
]

template ::File.join('/etc/systemd/network', "chef-#{iface}.network") do
  source 'ini.erb'
  variables(
    sections: network,
    comment: ';',
  )
  notifies :restart, "systemd_unit[#{resolved}]", :delayed
  notifies :restart, "systemd_unit[#{networkd}]", :delayed
end
