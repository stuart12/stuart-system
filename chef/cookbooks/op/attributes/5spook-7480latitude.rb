return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '9598eec9-7ec3-4b0f-b731-f5ee47716a3e'

%w[
  vim-gtk3
].each do |pkg|
  CfgHelper.add_package pkg
end

CfgHelper.activate 'desktop'
