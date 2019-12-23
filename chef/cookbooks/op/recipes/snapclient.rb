ck = 'stuart'
name = 'snapclient'
activated = node[ck].dig('config', name, 'activate')

systemd_unit "#{name}.service" do
  action :nothing
end

file "/etc/default/#{name}" do
  content "# Maintained by Chef\nSNAPCLIENT_OPTS='--hostID #{node.name}'\n"
  mode 0o444
  notifies :restart, "systemd_unit[#{name}.service]"
  only_if { activated }
end
