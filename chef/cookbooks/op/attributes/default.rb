CfgHelper.attributes(
  %w[scripts],
  bin: '/usr/local/bin',
)

CfgHelper.attributes(
  [],
  workstation: 'kooka',
  mqtt: {
    user: 'skldhf84d',
  },
  timezone: {
    name: 'Europe/Paris',
  },
)
CfgHelper.my_repo('python-scripts')

CfgHelper.attributes(
  %w[networking],
  mask: 24,
  dns: '192.168.0.254',
  gateway: '192.168.0.254',
)

%w[
  git
  libpam-tmpdir
  ntp
  openssh-client
  rsync
  rubocop
  vim
].each do |pkg|
  CfgHelper.add_package pkg
end
# rubocop:disable Layout/LineLength
CfgHelper.attributes(
  %w[users ssh_keys],
  'stuart@kooka' => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA34JVpS1wfN99SxuuwKQBKgUxOu6JmJq1ANO/A+/Iypabn3AbEyeXUCJPQe+VY/p8Opk01Ywm6h/vAQgHILGVDsBR0EQ4Ku444PXACBfdLkShclOR3LIUq3BDaZq1LJTryPQhqhnTBhLUvUvQy4RtLB8grKIEMcyGRcAr+1Uo4Bf+VU2VdFbW+dJb45jM66pd20/tmhBTFwHee8BO32nJKYHXdmgHOIci29bzPBJGnD0M3HFzbh9qgCLuTCWx9/77TogO28TPhoVP7BoOAji4YJxxzT/0CMeAoTRQaFB2aMAo56Ix+Pxnx2GYDq83NUWjjVBnTovlxIXxK7VcSlt7WQ==',
)
# rubocop:enable Layout/LineLength

CfgHelper.attributes(
  %w[work],
  group: 'work',
)
