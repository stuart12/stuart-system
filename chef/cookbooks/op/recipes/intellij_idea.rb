return unless CfgHelper.activated? 'intellij_idea'

package 'snapd' do
  action :upgrade
end

snap = 'intellij-idea-ultimate'
executable = ::File.join('/snap/bin', snap)

template ::File.join(CfgHelper.config['scripts']['bin'], 'idea') do
  variables(command: "#{executable} \"$@\"")
  source 'shell_script.erb'
  owner 'root'
  group CfgHelper.config['work']['group']
  mode 0o754
end

log "snap_package #{snap} hangs with chef 15.8.25, so install #{snap} by hand" do
  level :warn
  not_if { ::File.exist? executable }
end

snap_package snap do # https://www.jetbrains.com/idea/download/#section=linux
  options '--classic'
  action :upgrade
  not_if { ::File.exist? executable } # skip as hangs with chef 15.8.25
end

log "skipping update of snap #{snap} due to hang with chef 15.8.25 & snapd 2.42.1-1" do
  level :warn
end
