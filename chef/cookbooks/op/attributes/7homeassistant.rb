ck = 'stuart'
name = 'homeassistant'
return unless CfgHelper.activated? name
default[ck]['config'][name]['user'] = name
default[ck]['config'][name]['group'] = name
default[ck]['config'][name]['root'] = '/srv'

default[ck]['config']['systemd']['units']["#{name}.service"]['content'] =
  if node[ck].dig('config', name, 'activate')
    cfg = node[ck].dig('config', 'homeassistant')
    group = cfg['group']
    user = cfg['user']
    home = ::File.join(cfg['root'], name)
    %w[
      evtest
      libffi-dev
      libssl-dev
      python3
      python3-pip
      python3-venv
      python3-wheel
    ].each do |pkg|
      default[ck]['config']['packages']['install'][pkg] = true
    end
    gitdir = node[ck]['config']['git-stuart']['root']
    path = (['python-scripts', 'delcom-clock'].map { |v| ::File.join(gitdir, v) } + [
      '/usr/local/sbin',
      '/usr/local/bin',
      '/usr/sbin',
      '/usr/bin',
      '/sbin',
      '/bin',
    ]).join(':')
    allow = []
    groups = []
    if cfg.dig('audio')
      allow << 'char-alsa rwm'
      groups << 'audio'
    end
    if cfg.dig('keyboard')
      CfgHelper.add_package 'evtest'
      allow << 'char-input rw'
      groups << 'input'
      #     default[ck]['config']['udev']['rules'][name]['rules']['Ortek-numeric-keyboard'] = [
      #       'KERNEL=="event*"',
      #       'SUBSYSTEM=="input"',
      #       'ENV{ID_VENDOR}=="ORTEK"',
      #       'ENV{ID_MODEL}=="USB_Keyboard_Hub"',
      #       'ENV{ID_INPUT_KEYBOARD}=="1"',
      #       "GROUP=\"#{group}\"",
      #       'MODE="0660"',
      #     ]
      #     default[ck]['config']['udev']['rules'][name]['rules']['mini-keyboard'] = [
      #       'KERNEL=="event*"',
      #       'SUBSYSTEM=="input"',
      #       'ENV{ID_VENDOR}=="04d9"',
      #       'ENV{ID_MODEL}=="USB_Keyboard"',
      #       'ENV{ID_INPUT_KEYBOARD}=="1"',
      #       "GROUP=\"#{group}\"",
      #       'MODE="0660"',
      #     ]
    end
    if cfg.dig('IR')
      allow << '/dev/lirc0 rw'
      groups << 'video'
    end
    if cfg.dig('z-wave')
      default[ck]['config']['boot']['config']['options']['enable_uart'] = 1
      allow << '/dev/z-wave rw'
      default[ck]['config']['udev']['rules'][name]['rules']['z-wave'] = [
        'SUBSYSTEM=="tty"',
        'ATTRS{idProduct}=="0002"',
        'ATTRS{idVendor}=="1d6b"',
        'SYMLINK+="z-wave"',
        "GROUP=\"#{group}\"",
      ]
    end
    if cfg.dig('blinksticklight')
      allow << 'char-usb_device rwm'
      default[ck]['config']['udev']['rules'][name]['rules']['blinksticklight'] = [
        'SUBSYSTEM=="usb"',
        'ATTR{product}=="BlinkStick"',
        'ATTR{idVendor}=="20a0"',
        'ATTR{idProduct}=="41e5"',
        'MODE="0660"',
        "GROUP=\"#{group}\"",
      ]
    end
    version = cfg['version']
    unit_service = {
      User: user,
      Group: group,
      RuntimeDirectory: '%N',
      WorkingDirectory: '/tmp',
      Environment: [
        'HOME=/tmp',
        "PATH=#{path}",
        "XDG_CACHE_HOME=#{::File.join(home, 'cache')}",
      ],
      # https://www.home-assistant.io/docs/installation/raspberry-pi/',
      ExecStartPre: [
        '/usr/bin/python3 -m venv ve',
        "/bin/sh -c '. ve/bin/activate && python3 -m pip install homeassistant#{version ? "===#{version}" : ''}'",
      ],
      ExecStart: "/bin/sh -c '. ve/bin/activate && exec hass -c #{::File.join(home, 'config')} --log-file /tmp/hass.log'",
      TimeoutStartSec: '22min',
      ReadWritePaths: home,
      ProtectHome: true,
      PrivateUsers: true,
      PrivateTmp: true,
      CapabilityBoundingSet: '',
      NoNewPrivileges: true,
      ProtectControlGroups: true,
      ProtectKernelModules: true,
      ProtectKernelTunables: true,
      ProtectSystem: 'strict',
      RestrictAddressFamilies: 'AF_UNIX AF_INET AF_INET6 AF_NETLINK',
      DevicePolicy: allow.empty? ? 'closed' : 'auto',
      DeviceAllow: allow.sort,
      SupplementaryGroups:  groups.sort,
    }
    {
      Unit: {
        Description: 'Home Assistant',
        After: ['network-online.target', 'mosquitto.service'],
        Wants: 'network-online.target',
      },
      Service: unit_service,
      Install: {
        WantedBy: 'multi-user.target',
      },
    }
  else
    {}
  end
