networking = CfgHelper.config['networking']

return unless networking

network = CfgHelper.network

hostname = networking['hostname']
ip_base = networking.dig('hosts', hostname)
router = networking['gateway']
dns = networking['dns']
mask = networking['mask']

return unless hostname && ip_base && router && dns && mask && network

ip = IPAddr.new(ip_base) | network

ohai 'reload' do
  action :nothing
end

execute 'hostname' do
  command "hostname #{hostname}"
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

if platform? 'debian'
  systemd_unit 'systemd-networkd' do
    action :nothing
  end

  template '/etc/systemd/network/chef.network' do
    source 'ini.erb'
    variables(
      sections: {
        Match: {
          Name: networking['interface'] || raise('no attribute to define network interface'),
        },
        Network: {
          Address: "#{ip}/#{mask}",
          Gateway: router,
          DNS: dns,
        },
      },
    )
    notifies :restart, 'systemd_unit[systemd-networkd]', :immediately
    notifies :reload, 'ohai[reload]', :immediately
  end
end
