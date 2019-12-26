ck = 'stuart'

return unless platform? 'raspbian'

# rubocop:disable LineLength
default[ck]['config']['users']['ssh_keys'] =
  {
    'stuart@kooka' => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA34JVpS1wfN99SxuuwKQBKgUxOu6JmJq1ANO/A+/Iypabn3AbEyeXUCJPQe+VY/p8Opk01Ywm6h/vAQgHILGVDsBR0EQ4Ku444PXACBfdLkShclOR3LIUq3BDaZq1LJTryPQhqhnTBhLUvUvQy4RtLB8grKIEMcyGRcAr+1Uo4Bf+VU2VdFbW+dJb45jM66pd20/tmhBTFwHee8BO32nJKYHXdmgHOIci29bzPBJGnD0M3HFzbh9qgCLuTCWx9/77TogO28TPhoVP7BoOAji4YJxxzT/0CMeAoTRQaFB2aMAo56Ix+Pxnx2GYDq83NUWjjVBnTovlxIXxK7VcSlt7WQ==',
  }
# rubocop:enable LineLength
default[ck]['config']['users']['password'] = '$1$PGiJPcck$lQpIrARzg6Aa5Mh/Sg9wO1'
default[ck]['config']['users']['users'] = node['etc']['passwd'].select { |_, cfg| cfg['uid'].between?(1000, 2000) }.keys

default[ck]['config']['sshd']['activate'] = true
default[ck]['config']['firewall']['activate'] = true

default[ck]['config']['boot']['config']['leds'] = true

CfgHelper.add_package 'ruby-shadow' # required by Chef's password resource
