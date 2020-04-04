service = 'homeassistant'
return unless CfgHelper.activated? service

cfg = CfgHelper.config([service]) || {}

if cfg.dig('z-wave')
  CfgHelper.attributes(%w[boot config options enable_uart], 1)
  CfgHelper.attributes(
    ['udev', 'rules', name, 'rules', 'z-wave'],
    [
      'SUBSYSTEM=="tty"',
      'ATTRS{idProduct}=="0002"',
      'ATTRS{idVendor}=="1d6b"',
      'SYMLINK+="z-wave"',
      "GROUP=\"#{group}\"",
    ],
  )
end
if cfg.dig('blinksticklight')
  CfgHelper.attributes(
    ['udev', 'rules', name, 'rules', 'blinksticklight'],
    [
      'SUBSYSTEM=="usb"',
      'ATTR{product}=="BlinkStick"',
      'ATTR{idVendor}=="20a0"',
      'ATTR{idProduct}=="41e5"',
      'MODE="0660"',
      "GROUP=\"#{group}\"",
    ],
  )
end
