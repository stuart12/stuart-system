return unless CfgHelper.activated? 'desktop'

package %w[
  unattended-upgrades
] do
  action :remove
end

template '/etc/apt/preferences.d/chef' do
  source 'apt.preferences.erb'
  variables(packages: { unison: {} })
end
package 'unison'
