systemd_unit 'chef-client' do
  action %i[stop disable]
end

cookbook_file '/etc/inputrc' do
  mode 0o644
  user 'root'
end
