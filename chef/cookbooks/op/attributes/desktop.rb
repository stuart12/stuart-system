return unless CfgHelper.activated? 'desktop'

CfgHelper.attributes(%w[tmp options], size: 'size=2G')
CfgHelper.activate 'vpn'
CfgHelper.activate 'dbeaver'
CfgHelper.activate 'gnucash'
CfgHelper.activate 'remote_scanner'

%w[
  adb
  alsa-utils
  apt-file
  arandr
  btrfs-progs
  chromium
  dc
  displaycal
  dnsutils
  dos2unix
  edid-decode
  eric
  evince
  eyed3
  fastboot
  fbreader
  fdupes
  firefox-esr
  firmware-misc-nonfree
  flpsed
  geeqie
  gimp
  gitk
  gnupg2
  heimdall-flash
  hunspell-en-au
  hunspell-en-gb
  hunspell-fr
  id3v2
  iftop
  jq
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
  ltrace
  lxde
  memtest86+
  nmap
  pdftk-java
  pinentry-gtk2
  python3-cffi
  python3-defusedxml
  python3-doc
  python3-flask
  python3-flaskext.wtf
  python3-furl
  python3-jinja2
  python3-msgpack
  python3-packaging
  python3-passlib
  python3-peewee
  python3-pip
  python3-psutil
  python3-py
  python3-pycparser
  python3-pyparsing
  python3-requests
  python3-socks
  python3-virtualenv
  python3-vobject
  qemu-system-gui
  qemu-system-x86
  rawtherapee
  rename
  rubocop
  ruby-shadow
  sox
  strace
  sudo
  unison
  vim-gtk3
  x11-utils
  xdu
  xournal
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
