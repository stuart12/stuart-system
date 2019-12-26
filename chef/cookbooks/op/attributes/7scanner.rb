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

_debug_commands = <<~DEBUGCOMMANDS
  /etc/sane.d/saned.conf:

  Daemon options
  Port range for the data connection. Choose a range inside [1024 - 65535].
  Avoid specifying too large a range, for performance reasons.

  ONLY use this if your saned server is sitting behind a firewall. If your
  firewall is a Linux machine, we strongly recommend using the
  Netfilter nf_conntrack_sane connection tracking module instead.

  data_portrange = 10000 - 10100

  ferm 2.4

DEBUGCOMMANDS
