ck = 'stuart'

default[ck]['config']['git']['directory'] = '/opt'
default[ck]['config']['git-stuart']['root'] = ::File.join('/', 'opt', 'github.com', 'stuart12')
default[ck]['config']['git']['name'] = 'Stuart Pook'
default[ck]['config']['git']['email'] = 'stuart12'
default[ck]['config']['git']['stuart12']['python-scripts'] = true

# default[ck]['config']['homeassistant']['version'] = '0.70.4'

default[ck]['config']['networking']['mask'] = 24
default[ck]['config']['networking']['dns'] = '192.168.0.254'
default[ck]['config']['networking']['gateway'] = '192.168.0.254'
{
  'bathroom' => 29,
  'bedroom' => 25,
  'entrance' => 30,
  'kooka' => 8,
}.each do |host, addr|
  default[ck]['config']['networking']['hosts'][host] = "0.0.0.#{addr}"
end

default[ck]['config']['mqtt']['user'] = 'skldhf84d'
default[ck]['config']['timezone']['name'] = 'Europe/Paris'

%w[
  en_AU
  en_GB
  en_IE
  fr_FR
].each do |locale|
  default[ck]['config']['locale']['UTF-8'][locale] = true
end

%w[
  git
  foodcritic
  libpam-tmpdir
  ntp
  rubocop
  vim
].each do |pkg|
  default[ck]['config']['packages']['install'][pkg] = true
end
