systemd_unit 'chef-client' do
  action %i[stop disable]
end

cookbook_file '/etc/inputrc' do
  mode 0o644
  user 'root'
end

locales = CfgHelper.attributes(
  ['locale', 'UTF-8'],
  %w[
    en_AU
    en_GB
    en_IE
    fr_FR
  ].map { |locale| [locale, true] }.to_h,
).select { |_, v| v }.keys

execute 'locale-gen' do
  action :nothing
end
template '/etc/locale.gen' do
  variables(utf8: locales)
  notifies :run, 'execute[locale-gen]'
  mode 0o644
  user 'root'
end
