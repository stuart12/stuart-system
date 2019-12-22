ck = 'stuart'

return unless node[ck].dig('config', 'i2c', 'activate')

default[ck]['config']['boot']['config']['dtparam']['i2c_arm'] = 'on'
