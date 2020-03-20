return unless CfgHelper.activated? 'gradle'

CfgHelper.attributes(
  %w[gradle],
  install: '/opt/gradle',
  url: 'https://services.gradle.org/distributions/gradle-5.6.4-all.zip',
  checksum: 'abc10bcedb58806e8654210f96031db541bcd2d6fc3161e81cb0572d6a15e821',
  permissions: '750',
  group: 'work',
)
