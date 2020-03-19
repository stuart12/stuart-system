return unless CfgHelper.activated? 'desktop'

password = '$5$hyT2QdPt$jPJrQCssI..EcIbl8yGh/PVVBiz/tPI5VRLzFOI8nS.'
groups = %w[
  audio
  cdrom
  floppy
  lp
  netdev
  plugdev
  scanner
  video
] # https://wiki.debian.org/SystemGroups#Groups_without_an_associated_user

CfgHelper.attributes(
  %w[users real],
  's.pook' => {
    password: password,
    name: 'Stuart L Pook',
    groups: groups + %w[
      work
    ],
  },
  stuart: {
    password: password,
    name: 'Stuart Pook',
    groups: groups + %w[
      adm
      systemd-journal
    ],
  },
)
