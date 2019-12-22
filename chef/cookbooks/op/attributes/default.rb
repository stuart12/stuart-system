ck = 'stuart'

default[ck]['config']['git']['directory'] = '/opt'
default[ck]['config']['git-stuart']['root'] = ::File.join('/', 'opt', 'github.com', 'stuart12')
default[ck]['config']['git']['name'] = 'Stuart Pook'
default[ck]['config']['git']['email'] = 'stuart12'
default[ck]['config']['git']['stuart12']['python-scripts'] = true

default[ck]['config']['mqtt']['user'] = 'skldhf84d'
default[ck]['config']['timezone']['name'] = 'Europe/Paris'

default[ck]['config']['locale']['UTF-8'] = {
  'fr_FR' => true,
  'en_IE' => true,
  'en_AU' => true,
  'en_GB' => true,
}

%w[
  git
  foodcritic
  libpam-tmpdir
  ntp
  rubocop
].each do |pkg|
  default[ck]['config']['packages']['install'][pkg] = true
end
