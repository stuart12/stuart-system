return unless CfgHelper.activated? 'scanner'

systemd_unit 'saned.socket' do
  action %i[enable start]
end

file '/etc/sane.d/saned.conf' do
  content "# Maintained by Chef\nkooka\n"
  action :create
  notifies :restart, 'systemd_unit[saned.socket]', :delayed
end
