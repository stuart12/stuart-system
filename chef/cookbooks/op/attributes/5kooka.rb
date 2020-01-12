return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '315c4bf7-9da3-4377-8c63-1d4005fce534'

%w[
  vim-gtk3
].each do |pkg|
  CfgHelper.add_package pkg
end
