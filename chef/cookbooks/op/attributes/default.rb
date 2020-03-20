git_root = '/opt/chef-git'
CfgHelper.configure(
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
  name: 'Stuart Pook',
  email: 'stuart12',
  hosts: {
    'github.com' => {
      users: {
        stuart12: {
          repos: {
            'python-scripts' => true,
          },
        },
      },
    },
  },
)

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
  }.transform_values { |addr| "0.0.0.#{addr}" },
)

%w[
  git
  libpam-tmpdir
  ntp
  openssh-client
  rubocop
  vim
].each do |pkg|
  CfgHelper.add_package pkg
end
