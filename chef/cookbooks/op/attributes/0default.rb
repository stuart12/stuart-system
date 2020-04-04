# attributes used by other attributes or overrides

CfgHelper.attributes(%w[git directory], '/opt/git-chef')

CfgHelper.attributes(
  %w[tmp options],
  size: 'size=513M',
  dev: 'nodev',
  suid: 'nosuid',
)
