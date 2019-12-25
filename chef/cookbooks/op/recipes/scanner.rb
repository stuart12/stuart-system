ck = node['stuart']
name = 'scanner'
activated = ck.dig('config', name, 'activate')

systemd_unit 'saned.socket' do
  action activated ? %i[enable start] : %i[disable stop]
end

file '/etc/sane.d/saned.conf' do
  content "# Maintained by Chef\nkooka\n"
  action activated ? :create : :delete
end
