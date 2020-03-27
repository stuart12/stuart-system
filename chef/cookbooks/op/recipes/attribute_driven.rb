apt_update

CfgHelper.config(%w[packages install]).each do |package, wanted|
  package package do
    action wanted ? :upgrade : :nothing
  end
end

rules = CfgHelper.config(%w[udev rules])
template '/etc/udev/rules.d/99-zzz-chef.rules' do
  source 'udev.rules.erb'
  user 'root'
  mode 0o644
  variables(
    rules: rules,
  )
  action rules.empty? ? :delete : :create
end

CfgHelper.config(%w[git hosts]).each do |host, cfg|
  (cfg['users'] || {}).each do |user, ucfg|
    (ucfg['repos'] || {}).each do |repo, activated|
      dir = CfgHelper.config('git', 'directory')
      [dir, ::File.join(dir, host), ::File.join(dir, host, user)].each do |d|
        directory d do
          user 'root'
          mode 0o755
          only_if { activated }
        end
      end
      git ::File.join(dir, host, user, repo) do
        repository ::File.join('https://', host, user, repo)
        revision 'master'
        user 'root'
        only_if { activated }
      end
    end
  end
end

CfgHelper.config(%w[systemd units]).each do |name, cfg|
  content = cfg['content']
  on = !content.empty? && (cfg['what'].nil? || CfgHelper.activated?(cfg['what']))
  systemd_unit name do
    action(on ? %i[create enable] : %i[stop disable])
    content content
    notifies(:restart, "systemd_unit[#{name}]", :delayed) unless name.include?('@') || !on
  end
end

template '/etc/xdg/mimeapps.list' do
  source 'ini.erb'
  variables sections: CfgHelper.attributes(
    %w[mime defaults],
    'Default Applications': {
      'x-scheme-handler/http': 'firefox.desktop',
      'x-scheme-handler/https': 'firefox.desktop',
    },
  )
  owner 'root'
  mode 0o644
end
