return unless CfgHelper.activated? 'desktop'

CfgHelper.activate 'nvm'

%w[
  libgdiplus
].each do |pkg|
  CfgHelper.add_package pkg
end
