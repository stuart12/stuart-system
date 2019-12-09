ck = 'stuart'

i2c = node[ck]['config']['i2c']

%w[i2c-tools].each do |pkg|
  package pkg do
    action i2c ? :upgrade : :remove
  end
end

return unless i2c
