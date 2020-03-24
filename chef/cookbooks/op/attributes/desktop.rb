return unless CfgHelper.activated? 'desktop'

%w[
  apt-file
  arandr
  btrfs-progs
  chromium
  dnsutils
  evince
  firefox
  geeqie
  gimp
  libnetty-java
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
].each do |pkg|
  CfgHelper.add_package pkg
end

groups = %w[
  cdrom
  floppy
  lp
  netdev
  plugdev
  scanner
  video
] # https://wiki.debian.org/SystemGroups#Groups_without_an_associated_user

CfgHelper.attributes(
  %w[users users],
  's.pook' => {
    name: 'Stuart L Pook',
    work: true,
    groups: groups + %w[
    ],
  },
  stuart: {
    name: 'Stuart Pook',
    sudo: true,
    groups: groups + %w[
      adm
      systemd-journal
    ],
  },
)

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
