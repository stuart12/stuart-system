name = 'dbeaver'
return unless CfgHelper.activated? name

cfg = CfgHelper.attributes(
  [name],
  url: 'https://dbeaver.io/files/21.1.0/dbeaver-ce-21.1.0-linux.gtk.x86_64-nojdk.tar.gz',
  checksum: 'd04e485d75bf68821ee7b2b7a0b356153ebd49984e53023823dd2b31b13d89df', # sha256sum
  where: '/opt',
  mode: 0o754,
)

remote_tar name do
  url cfg['url']
  checksum cfg['checksum']
  group CfgHelper.config(%w[work group])
  mode cfg['mode']
  where cfg['where']
  executable ::File.join(name, name)
end
