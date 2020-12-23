return unless CfgHelper.activated? 'vpn'

paquet 'openconnect'
paquet 'vpnc'

cfg = CfgHelper.attributes(
  %w[vpn config],
  ssl: {
    country: 'FR',
    organization: 'Criteo',
    organizationalunit: 'IT',
    fullname: '',
  },
)

ssl = cfg['ssl']
etc_org = ::File.join('/etc', ssl['organization'])

request_dir = Chef::Config[:file_cache_path]
criteo_key = ::File.join(etc_org, 'my.key')

execute "openssl genrsa -out #{criteo_key} 2048" do
  creates criteo_key
  umask 0o066
end

criteo_csr = ::File.join(request_dir, 'myidentity.csr')
subject = "/C=#{ssl['country']}/O=#{ssl['organization']}/OU=#{ssl['organizationalunit']}/CN=#{ssl['fullname']}"
execute "openssl req -new -key #{criteo_key} -out #{criteo_csr} -subj #{subject}" do
  creates criteo_csr
end

lib = CfgHelper.attributes(%w[scripts lib], '/usr/local/lib')
csdpost = ::File.join(lib, 'csd-post')

# https://confluence.criteois.com/pages/viewpage.action?spaceKey=IITP&title=How+to+-+Install+and+setup+OpenConnect+for+Linux
# By default the file is saved as certnew.cer. Copy it to #{signed_certificate}
signed_certificate = ::File.join(etc_org, 'certnew.cer')
command = [
  '/sbin/openconnect',
  {
    'csd-user': 'games', # FIXME: create a user
    certificate: signed_certificate,
    sslkey: criteo_key,
    'csd-wrapper': csdpost,
    script: '/usr/share/vpnc-scripts/vpnc-script',
  }.map { |k, v| "--#{k}=#{v}" },
  CfgHelper.secret(%w[work prod-vpn gateway]),
].join(' ')

template ::File.join(CfgHelper.config(%w[scripts bin]), 'vpn') do
  variables(
    command: "sudo #{command}",
  )
  source 'shell_script.erb'
  mode 0o755
  owner 'root'
end

sudo 'chef-vpn' do
  commands [
    command,
  ]
  users CfgHelper.secret(%w[work ldap username])
  nopasswd true
end

vpnc_dir = '/etc/vpnc'

directory vpnc_dir do
  mode 0o755
end

domains = CfgHelper.secret(%w[work internal domains])
%w[connect disconnect].each do |reason|
  dir = ::File.join(vpnc_dir, "#{reason}.d")
  directory dir do
    mode 0o755
  end
  template ::File.join(dir, 'chef-resolvectl') do
    source 'vpnc-resolvectl.erb'
    variables(
      domains: domains.sort.join(','),
    )
    owner 'root'
    mode 0o644
    action domains.empty? ? :delete : :create
  end
end

cookbook_file csdpost do
  source 'csd-post.sh'
  mode 0o755
end

# cleanup old stuff

script = ::File.join(lib, 'vpnc-script')
iface = 'chef0'
vpn = 'prod'
template "/etc/vpnc/#{vpn}.conf" do
  source 'lines.erb'
  action :delete # FIXME: remove
end

sudo vpn do
  action :delete
end

cookbook_file script do
  source 'vpnc-script.sh'
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

template ::File.join('/etc/systemd/network', "chef-#{iface}.network") do
  source 'ini.erb'
  notifies :restart, "systemd_unit[#{resolved}]", :delayed
  notifies :restart, "systemd_unit[#{networkd}]", :delayed
  action :delete # FIXME: remove
end
