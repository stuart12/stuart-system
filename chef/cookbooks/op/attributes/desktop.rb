return unless CfgHelper.activated? 'desktop'

password = '$5$hyT2QdPt$jPJrQCssI..EcIbl8yGh/PVVBiz/tPI5VRLzFOI8nS.'
CfgHelper.attributes(
  %w[users real],
  's.pook' => {
    password: password,
    name: 'Stuart L Pook',
  },
  stuart: {
    password: password,
    name: 'Stuart Pook',
  },
)
