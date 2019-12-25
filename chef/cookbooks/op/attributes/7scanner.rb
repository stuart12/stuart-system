ck = 'stuart'
name = 'scanner'
return unless node[ck].dig('config', name, 'activate')

default[ck]['config']['udev']['rules'][name]['rules']['CanoScan9000F'] = [
  'ATTRS{idVendor}=="04a9"',
  'ATTRS{idProduct}=="190d"',
  'ENV{libsane_matched}="yes"',
  'MODE="0664"',
  'GROUP="scanner"',
]

%w[
  sane-utils
].each do |pkg|
  default[ck]['config']['packages']['install'][pkg] = true
end
