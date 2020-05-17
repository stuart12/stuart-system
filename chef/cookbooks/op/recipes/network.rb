networking = CfgHelper.config['networking']

return unless networking

network = CfgHelper.network

hostname = networking['hostname'] || raise("hostname not set in #{networking}")
ip_base = "0.0.0.#{networking.dig('hosts', hostname)}"
router = networking['gateway']
dns = networking['dns']
mask = networking['mask']

systemd_unit 'systemd-networkd' do
  action :nothing
end

ohai 'reload' do
  action :nothing
end

execute "hostname #{hostname}" do
  not_if { hostname == node.name.split('.')[0] }
  notifies :reload, 'ohai[reload]', :immediately
end
file '/etc/hostname' do
  # use hostname resource in Chef 14.0
  content "#{hostname}\n"
end

template '/etc/hosts' do
  source 'hostname.erb'
  variables(
    hosts: networking['hosts']
      .select { |_, a| a }
      .transform_values { |addr| "0.0.0.#{addr}" }
      .transform_values { |addr| IPAddr.new(addr) | network }
      .merge(router: CfgHelper.config(%w[networking gateway]))
      .map { |k, v| [v, k] },
  )
end

ip = networking['dhcp'] ? nil : (IPAddr.new(ip_base) | network)

if platform? 'debian'

  interfaces = node['network']['interfaces'].select { |_, c| c['encapsulation'] == 'Ethernet' && c['state'] == 'up' }.keys
  raise "wanted only one interface, found #{interfaces}" unless interfaces.length == 1

  file '/etc/systemd/network/chef.network' do
    action :delete
  end
  file '/etc/network/interfaces' do
    action :delete
  end

  chef_main =
    if ip
      {
        Address: "#{ip}/#{mask}",
        Gateway: router,
        DNS: dns,
      }
    else
      {
        DHCP: 'yes',
      }
    end.merge({ Domains: '~.' }) # for conditional forwarding by systemd-resolved

  systemd_unit 'systemd-resolved' do
    action :enable
  end

  template '/etc/systemd/network/chef-main.network' do
    source 'ini.erb'
    variables(
      comment: ';',
      sections: {
        Match: {
          Name: interfaces.first,
        },
        Network: chef_main,
      },
    )
    notifies :restart, 'systemd_unit[systemd-networkd]', :immediately
    notifies :restart, 'systemd_unit[systemd-resolved]', :immediately
    notifies :reload, 'ohai[reload]', :immediately
  end
  link '/etc/resolv.conf' do
    to '/run/systemd/resolve/stub-resolv.conf'
  end
else

  systemd_unit 'dhcpcd' do
    action :nothing
  end

  template '/etc/dhcpcd.conf' do
    source 'dhcpcd.conf.erb'
    variables(
      ip: ip,
      router: router,
      dns: dns,
      mask: mask,
    )
    user 'root'
    mode 0o644
    notifies :restart, 'systemd_unit[dhcpcd]', :immediately
    notifies :reload, 'ohai[reload]', :immediately
  end
end
