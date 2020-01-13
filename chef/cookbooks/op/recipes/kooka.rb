return unless CfgHelper.activated? 'kooka'

package %w[
  wpasupplicant
] do
  action :remove
end

systemd_unit 'ssh' do
  action %i[disable stop]
end
