# FIXME: need to add password

ck = 'stuart'

mqtt = node[ck]['config']['mqtt']

%w[mosquitto-clients mosquitto].each do |pkg|
  package pkg do
    action mqtt ? :upgrade : :remove
  end
end

return unless mqtt

# execute 'mosquitto_passwd' do
#  command ['mosquitto_passwd', '-b', node[ck]['config']['mqtt']['user']
