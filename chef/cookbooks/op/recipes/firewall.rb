ck = node['stuart']

activated = ck.dig('config', 'firewall', 'activate')

%w[ferm].each do |pkg|
  package pkg do
    action activated ? :upgrade : :remove
  end
end

systemd_unit 'ferm.service' do
  action :nothing
end

addresses =
  node['network']['interfaces']
  .values
  .select { |cfg| cfg['flags'].include?('BROADCAST') }
  .map { |cfg| cfg['addresses'] }

ipv4 = addresses
       .map(&:values)
       .flatten
       .select { |v| v['family'] == 'inet' && v['scope'].casecmp('global').zero? }
       .first
# broadcast = ipv4['broadcast']
prefixlen = ipv4['prefixlen']

variables = {
  ipaddress: node['ipaddress'],
  prefixlen: prefixlen,
  local: {
    tcp: {
      'sane-port' => 26, # FIXME: only on machine with a scanner!
      'ssh' => 26,
      1883 => 26, # mqtt/mosquitto,
    },
    udp: {
      21_027 => prefixlen, # Syncthing
    },
  },
  drop: {
    udp: [
      'netbios-dgm',
      57_621, # Spotify client P2P communication
    ],
  },
  multicast: {
    251 => 'mdns',
  },
}

template '/etc/ferm/ferm.conf' do
  source 'ferm.conf.erb'
  variables variables
  user 'root'
  mode 0o644
  notifies :restart, 'systemd_unit[ferm.service]' if activated
  action activated ? :create : :delete
end
