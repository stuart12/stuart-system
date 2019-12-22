ck = 'stuart'

%w[
  vim-gtk3
].each do |pkg|
  default[ck]['config']['packages']['install'][pkg] = true
end
