return unless CfgHelper.activated? 'desktop'

CfgHelper.attributes(%w[tmp options], size: 'size=2G')
CfgHelper.activate 'vpn'

%w[
  adb
  apt-file
  arandr
  btrfs-progs
  chromium
  dc
  displaycal
  dnsutils
  edid-decode
  enigmail
  evince
  fbreader
  fdupes
  firefox-esr
  firmware-misc-nonfree
  flpsed
  geeqie
  gimp
  gitk
  gnupg2
  hunspell-en-au
  hunspell-en-gb
  hunspell-fr
  iftop
  kexec-tools
  libguestfs-tools
  libimage-exiftool-perl
  libnetty-java
  libpodofo-utils
  libreoffice-calc
  libreoffice-writer
  libvips-dev
  lightdm
  linux-image-amd64
  lxde
  memtest86+
  pdftk-java
  python3-pip
  python3-psutil
  python3-requests
  python3-vobject
  qemu-system-gui
  qemu-system-x86
  rawtherapee
  rename
  ruby-shadow
  sox
  strace
  sudo
  unison
  vim-gtk3
  x11-utils
  xdu
  youtube-dl
  zbar-tools
].each do |pkg|
  CfgHelper.add_package pkg
end

CfgHelper.add_package 'libsqlcipher0' # for https://element.io/get-started

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
