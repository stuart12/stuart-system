ck = node['stuart']

(ck.dig('config', 'packages', 'install') || {}).each do |package, wanted|
  package package do
    action wanted ? :upgrade : :nothing
  end
end

rules = ck.dig('config', 'udev', 'rules') || {}
template '/etc/udev/rules.d/99-chef.rules' do
  source 'udev.rules.erb'
  user 'root'
  mode 0o644
  variables(
    rules: rules,
  )
  action rules.empty? ? :delete : :create
end

(ck.dig('config', 'systemd', 'units') || {}).each do |name, cfg|
  content = cfg['content']
  systemd_unit name do
    action(if content.empty?
             :delete
           else
             %i[create enable] + (name.include?('@') ? [] : %i[restart])
           end)
    content content
  end
end

repos = ck.dig('config', 'git-stuart', 'repos') || []
gitdir = ck['config']['git-stuart']['root']
directory gitdir do
  recursive true
  user 'root'
  mode 0o755
  not_if { repos.empty? }
end
repos.each do |name, activated|
  a = activated # https://github.com/Foodcritic/foodcritic/issues/436
  git ::File.join(gitdir, name) do
    repository ::File.join('https://github.com/stuart12', name)
    revision 'master'
    user 'root'
    only_if { a }
  end
end
