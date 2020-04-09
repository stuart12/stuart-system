paquet 'snapd'

file '/etc/profile.d/apps-bin-path.sh' do
  action :delete
end

file '/usr/bin/snap' do
  owner 'root'
  group CfgHelper.config['work']['group']
  mode 0o754
end
