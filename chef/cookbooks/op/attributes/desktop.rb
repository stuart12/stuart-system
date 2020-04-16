return unless CfgHelper.activated? 'desktop'

CfgHelper.attributes(%w[tmp options], size: 'size=2G')
CfgHelper.activate 'vpn'

%w[
  apt-file
  arandr
  btrfs-progs
  chromium
  dc
  dnsutils
  enigmail
  evince
  firmware-misc-nonfree
  geeqie
  gimp
  gitk
  hunspell-en-au
  hunspell-en-gb
  hunspell-fr
  iftop
  libnetty-java
  libreoffice-calc
  libreoffice-writer
  lightdm
  linux-image-amd64
  lxde
  memtest86+
  qemu-system-x86-64
  qtqr
  rawtherapee
  rename
  ruby-shadow
  strace
  sudo
  syncthing
  thunderbird
  unison
  vim-gtk3
  xdu
].each do |pkg|
  CfgHelper.add_package pkg
end

CfgHelper.attributes(
  %w[ssh hosts],
  'github.com': {
    IdentitiesOnly: 'yes',
    IdentityFile: '~/.ssh/github',
    silly: nil, # set the value to nil to skip the line
  },
  'gitlab.criteois.com': {
    IdentitiesOnly: 'yes',
    IdentityFile: '~/.ssh/gitlab.criteois.com',
  },
  windows10: {
    Host: %w[windows windows10],
    Hostname: '127.0.0.1',
    Port: '10022',
    IdentityFile: '%d/.ssh/windows10',
    LocalForward: 'localhost:64006 localhost:64006',
    ControlPath: '~/.ssh/controlmasters-%r@%h:%p',
    ControlMaster: 'auto',
    ControlPersist: '10m',
  },
  fuzbuz: {
    Host: nil, # set the host to nil to skip the host
    wooble: 'silly',
  },
)
