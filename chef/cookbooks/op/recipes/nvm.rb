name = 'nvm'
return unless CfgHelper.activated? name

where = ::File.join('/opt', name)
clone = ::File.join(where, 'clone')

directory where do
  group CfgHelper.config(%w[work group])
  mode 0o754
end

git clone do # should be a resource
  repository 'https://github.com/nvm-sh/nvm.git'
  branch 'v0.38.0'
  user 'root'
end

profile = ::File.join(clone, 'nvm.sh')

file '/etc/profile.d/chef-nvm.sh' do
  content [
    '# Maintained by Chef',
    "if [ -r #{profile} ]; then",
    'export NVM_DIR=$HOME/.nvm',
    "source #{profile}",
    "source #{::File.join(clone, 'bash_completion')}",
    'fi',
  ].join("\n") + "\n"
  owner 'root'
  mode 0o644
end
