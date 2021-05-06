name = 'postman'
return unless CfgHelper.activated? name

cfg = CfgHelper.attributes(
  [name],
  url: 'https://dl.pstmn.io/download/latest/linux64',
  checksum: 'a289a3f8d2474e27e9bc2e99a5a58f40dfc1a2c47322a38ab2b52efb9200a9e0', # sha256sum
  where: '/opt',
  mode: 0o754,
)

remote_tar name do
  url cfg['url']
  checksum cfg['checksum']
  group CfgHelper.config(%w[work group])
  mode cfg['mode']
  where cfg['where']
  executable 'Postman/Postman'
end
