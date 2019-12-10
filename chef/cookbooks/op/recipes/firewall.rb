ck = 'stuart'

firewall = node[ck]['config']['firewall']['activate']

%w[ferm].each do |pkg|
  package pkg do
    action firewall ? :upgrade : :remove
  end
end

systemd_unit 'ferm.service' do
  action :nothing
end

template '/etc/ferm/ferm.conf' do
  source 'ferm.conf.erb'
  variables(
    ipaddress: node['ipaddress'],
    tcp: {
      'ssh' => 26,
      '1883' => 26, # mqtt/mosquitto,
    },
    multicast: [
      251, # mDNS
    ],
  )
  user 'root'
  mode 0o644
  notifies :reload, 'systemd_unit[ferm.service]' if firewall
  action firewall ? :create : :delete
end
