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
    end.merge(
      {
        DNSSEC: false, # DNSSEC & systemd 245.5-2 -> DNSSEC validation failed for question
        Domains: '~.', # for conditional forwarding by systemd-resolved
      },
    )

  { '!*wifi*' => 100, '*wifi*' => 200 }.sort_by { |_, v| v }.each_with_index do |cfg, index|
    # get driver with: udevadm info /sys/class/net/wlp2s0 | grep ID_NET_DRIVER
    driver, metric = cfg
    template "/etc/systemd/network/chef-driver#{index}.network" do
      # man systemd.network
      source 'ini.erb'
      variables(
        comment: ';',
        sections: {
          Match: {
            Driver: driver,
            Path: '?*', # avoid matching lo
          },
          Network: chef_main,
          Route: {
            Metric: metric + 1, # not tested (add 1 to see which was used)
          },
          DHCP: {
            RouteMetric: metric,
          },
        },
      )
      notifies :restart, 'systemd_unit[systemd-networkd]'
      notifies :restart, 'systemd_unit[systemd-resolved]'
      notifies :reload, 'ohai[reload]'
    end
  end

  systemd_unit 'systemd-resolved' do
    action :enable
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
