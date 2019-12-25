ck = 'stuart'
return unless node[ck].dig('config', 'homeassistant', 'activate')

%w[
  evtest
  python3
  python3-venv
  python3-pip
  libffi-dev
  libssl-dev
].each do |pkg|
  default[ck]['config']['packages']['install'][pkg] = true
end
