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
    "\texport NVM_DIR=$HOME/.nvm",
    'fi',
  ].join("\n") + "\n"
  owner 'root'
  mode 0o644
end

file '/etc/bash_completion.d/chef-nvm' do # HACK: to get read in every bash
  content [
    '# Maintained by Chef',
    "if [ -r #{profile} -a -n \"$NVM_DIR\" ]; then",
    "\tsource #{profile}",
    "\tsource #{::File.join(clone, 'bash_completion')}",
    'fi',
  ].join("\n") + "\n"
  owner 'root'
  mode 0o644
end
