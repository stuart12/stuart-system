ck = node['stuart']

apt_update

(ck.dig('config', 'packages', 'install') || {}).each do |package, wanted|
  package package do
    action wanted ? :upgrade : :nothing
  end
end

rules = ck.dig('config', 'udev', 'rules') || {}
template '/etc/udev/rules.d/99-zzz-chef.rules' do
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
  on = !content.empty? && (cfg['what'].nil? || CfgHelper.activated?(cfg['what']))
  systemd_unit name do
    action(on ? %i[create enable] : %i[stop disable])
    content content
    notifies(:restart, "systemd_unit[#{name}]", :delayed) unless name.include?('@') || !on
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
