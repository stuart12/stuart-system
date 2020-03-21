CfgHelper.attributes(
  %w[scripts],
  bin: '/usr/local/bin',
)

git_root = '/opt/chef-git'
CfgHelper.attributes(
  [],
  workstation: 'kooka',
  mqtt: {
    user: 'skldhf84d',
  },
  timezone: {
    name: 'Europe/Paris',
  },
  'git-stuart' => {
    root: File.join(git_root, 'github.com', 'stuart12'),
  },
)

CfgHelper.attributes(
  %w[git],
  directory: git_root,
)
CfgHelper.my_repo('python-scripts')

CfgHelper.attributes(
  %w[networking],
  mask: 24,
  dns: '192.168.0.254',
  gateway: '192.168.0.254',
  hosts: {
    bathroom: 29,
    bedroom: 25,
    entrance: 30,
    kooka: 8,
    'spook-7480latitude' => 117,
  }.transform_values { |addr| "0.0.0.#{addr}" },
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
# rubocop:disable LineLength
CfgHelper.attributes(
  %w[users ssh_keys],
  'stuart@kooka' => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA34JVpS1wfN99SxuuwKQBKgUxOu6JmJq1ANO/A+/Iypabn3AbEyeXUCJPQe+VY/p8Opk01Ywm6h/vAQgHILGVDsBR0EQ4Ku444PXACBfdLkShclOR3LIUq3BDaZq1LJTryPQhqhnTBhLUvUvQy4RtLB8grKIEMcyGRcAr+1Uo4Bf+VU2VdFbW+dJb45jM66pd20/tmhBTFwHee8BO32nJKYHXdmgHOIci29bzPBJGnD0M3HFzbh9qgCLuTCWx9/77TogO28TPhoVP7BoOAji4YJxxzT/0CMeAoTRQaFB2aMAo56Ix+Pxnx2GYDq83NUWjjVBnTovlxIXxK7VcSlt7WQ==',
)
# rubocop:enable LineLength

CfgHelper.attributes(
  %w[work],
  group: 'work',
)
