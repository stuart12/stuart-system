return unless CfgHelper.activated? 'sane'

paquet 'xsane'

file '/etc/sane.d/net.conf' do
  content "# Maintained by Chef\nentrance\n"
  user 'root'
  mode 0o644
end
