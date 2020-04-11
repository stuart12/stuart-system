service = 'homeassistant'
return unless CfgHelper.activated? service

cfg = CfgHelper.attributes(
  [service],
  user: service,
  group: service,
  home: ::File.join('/srv', service),
)

if cfg.dig('z-wave')
  CfgHelper.attributes(%w[boot config options enable_uart], 1)
  CfgHelper.attributes(
    ['udev', 'rules', service, 'rules', 'z-wave'],
    [
      'SUBSYSTEM=="tty"',
      'ATTRS{idProduct}=="0002"',
      'ATTRS{idVendor}=="1d6b"',
      'SYMLINK+="z-wave"',
      "GROUP=\"#{cfg['group'] || raise("missing group for z-wave in #{cfg}")}\"",
    ],
  )
end
if cfg.dig('blinksticklight')
  CfgHelper.attributes(
    ['udev', 'rules', service, 'rules', 'blinksticklight'],
    [
      'SUBSYSTEM=="usb"',
      'ATTR{product}=="BlinkStick"',
      'ATTR{idVendor}=="20a0"',
      'ATTR{idProduct}=="41e5"',
      'MODE="0660"',
      "GROUP=\"#{cfg['group'] || raise("missing group for blinksticklight in #{cfg}")}\"",
    ],
  )
end
