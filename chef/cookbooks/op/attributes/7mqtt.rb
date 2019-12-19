ck = 'stuart'
return unless node[ck].dig('config', 'mqtt', 'activate')

%w[mosquitto-clients mosquitto].each do |pkg|
  default[ck]['config']['packages']['install'][pkg] = true
end

# FIXME: need to add password

# execute 'mosquitto_passwd' do
#  command ['mosquitto_passwd', '-b', node[ck]['config']['mqtt']['user']
