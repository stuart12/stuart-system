ohai 'reload' do
  action :nothing
end

file '/etc/chef/client.rb' do
  content "ohai.optional_plugins = [ :Passwd ]\n"
  mode 0o644
  owner 'root'
  notifies :reload, 'ohai[reload]', :immediately
end
