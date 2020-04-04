systemd_unit 'chef-client' do
  action %i[stop disable]
end

cookbook_file '/etc/inputrc' do
  mode 0o644
  user 'root'
end

locales = CfgHelper.attributes(
  %w[locale UTF-8],
  %w[
    en_AU
    en_GB
    en_IE
    fr_FR
  ].map { |locale| [locale, true] }.to_h,
).select { |_, v| v }.keys

execute 'locale-gen' do
  action :nothing
end
template '/etc/locale.gen' do
  variables(utf8: locales)
  notifies :run, 'execute[locale-gen]'
  mode 0o644
  user 'root'
end

gitconfig = CfgHelper.attributes(
  %w[git config],
  sections: {
    alias: {
      outgoing: 'log @{upstream}..',
      incoming: 'log ..@{upstream}',
      files: 'show --pretty= --name-only',
      amend: 'commit --amend',
      review: 'push origin HEAD:refs/publish/master',
    },
    branch: {
      autosetuprebase: 'always',
    },
    core: {
      pager: 'less -F -X',
    },
    pull: {
      rebase: true,
    },
    push: {
      default: 'simple',
    },
    user: {
      name: 'Stuart Pook',
      email: 'stuart12@users.noreply.github.com',
    },
  },
)

template '/etc/gitconfig' do
  source 'ini.erb'
  user 'root'
  mode 0o644
  variables(gitconfig)
end

['profile.d/shell_global_profile.sh'].each do |path|
  cookbook_file ::File.join('/etc/', path) do
    mode 0o644
    user 'root'
  end
end

cookbook_file '/etc/bash.bashrc' do
  source 'bashrc'
  user 'root'
  mode 0o644
end

mount '/tmp' do
  pass 0
  fstype 'tmpfs'
  device 'tmpfs'
  options %w[size=1023M nodev nosuid]
  action :enable # mount at next boot
end

template ::File.join(CfgHelper.config['scripts']['bin'], 'l') do
  variables(command: '/bin/ls -la "$@"')
  source 'shell_script.erb'
  mode 0o755
  owner 'root'
end

template '/etc/vim/vimrc.local' do
  source 'vimrc.erb'
  variables(
    CfgHelper.attributes(
      %w[vim gvimrc],
      set: {
        guifont: {
          'Monospace 9': '',
        },
        guioptions: {
          T: '-', # remove tool bar
          r: '-', # remove right-hand scroll bar
        },
        guicursor: {
          'a:blinkon0': '+', # Disable all blinking
        },
      },
      other: {
        colorscheme: 'torte',
      },
    ),
  )
  owner 'root'
  mode 0o644
end

file '/etc/ssh/ssh_config.d/chef.conf' do
  action :delete # no include on ssh on buster
end
CfgHelper.attributes(
  %w[ssh hosts *],
  SendEnv: %w[LANG LC_*],
  HashKnownHosts: 'yes',
  GSSAPIAuthentication: 'yes',
)
template '/etc/ssh/ssh_config' do # no include on ssh on buster
  source 'ssh_config.erb'
  variables(
    hosts: (CfgHelper.config(%w[ssh hosts]) || {})
    .reject { |_, cfg| cfg.key?('Host') && cfg['Host'].nil? }
    .transform_values { |cfg| cfg.select { |_, v| v } }
    .map { |host, cfg| [host, cfg.merge('Host' => cfg['Host'] || [host])] },
  )
  owner 'root'
  mode 0o644
end

if Chef::VERSION.to_f >= 14
  sudo 'chef-dmesg' do
    user CfgHelper.users.keys
    commands ['/usr/bin/dmesg']
    nopasswd true
  end
end
