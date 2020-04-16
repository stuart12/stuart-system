networking = CfgHelper.config['networking']

return unless networking

network = CfgHelper.network

hostname = networking['hostname']
ip_base = networking.dig('hosts', hostname)
router = networking['gateway']
dns = networking['dns']
mask = networking['mask']

systemd_unit 'systemd-networkd' do
  action :nothing
end
systemd_unit 'systemd-resolved' do
  action :nothing
end

ip = IPAddr.new(ip_base) | network

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
    if hostname && ip_base && router && dns && mask && network
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
    hosts: networking['hosts'].select { |_, a| a }.transform_values { |addr| IPAddr.new(addr) | network }.map { |k, v| [v, k] },
  )
end

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
  only_if { platform? 'raspbian' }
end
