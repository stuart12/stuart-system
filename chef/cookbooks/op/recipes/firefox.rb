return unless CfgHelper.activated? 'firefox'

firefox_cfg = CfgHelper.attributes(%w[firefox preferences])
                       .reject { |_, v| v.any?(&:nil?) }
                       .map do |pref, cfg|
  "#{cfg['priority']}(\"#{pref}\", \"#{cfg['value']}\");"
end

template '/etc/firefox/chef.js' do
  source 'lines.erb'
  variables(
    lines: firefox_cfg,
    comment: '//',
  )
  mode 0o644
  owner 'root'
end

file '/etc/firefox/local-settings.js' do
  action :delete
end
