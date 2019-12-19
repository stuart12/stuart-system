# FIXME: need to add password

ck = node['stuart']

activated = ck.dig('config', 'mqtt', 'activate')

%w[mosquitto-clients mosquitto].each do |pkg|
  package pkg do
    action activated ? :upgrade : :nothing
  end
end

# execute 'mosquitto_passwd' do
#  command ['mosquitto_passwd', '-b', node[ck]['config']['mqtt']['user']
