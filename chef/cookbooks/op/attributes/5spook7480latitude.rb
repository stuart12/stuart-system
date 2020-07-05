me = 'spook-7480latitude'

CfgHelper.attributes(%w[networking hosts], me => 3)

return unless node['filesystem']['by_mountpoint']['/']['uuid'] == '9598eec9-7ec3-4b0f-b731-f5ee47716a3e'

CfgHelper.activate 'desktop'
CfgHelper.activate 'sshd'
CfgHelper.activate 'gradle'
CfgHelper.activate 'intellij_idea'
CfgHelper.activate 'swap'
CfgHelper.activate 'zoom'
CfgHelper.activate 'slack'
CfgHelper.activate 'bluejeans'
CfgHelper.activate 'stuart'
CfgHelper.activate 'abank'
CfgHelper.activate 'sane'
CfgHelper.activate 'photo_transforms'

CfgHelper.add_package 'firmware-iwlwifi'

CfgHelper.attributes(
  %w[networking],
  hostname: me,
  dhcp: true,
)

# FIXME: only if machine has a i915?
CfgHelper.attributes(
  %w[firmware],
  url: 'https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/i915',
  destination: '/lib/firmware/i915',
  blobs: %w[
    icl_dmc_ver1_09
    tgl_dmc_ver2_04
    skl_huc_2.0.0
    bxt_huc_2.0.0
    kbl_huc_4.0.0
    glk_huc_4.0.0
    kbl_huc_4.0.0
    cml_huc_4.0.0
    cml_guc_33.0.0
    icl_huc_9.0.0
    ehl_huc_9.0.0
    ehl_guc_33.0.4
    tgl_huc_7.0.3
    tgl_guc_35.2.0
  ].map { |blob| [blob, true] }.to_h,
)

CfgHelper.override(
  %w[btrfs snapshot handler],
  hour: '9-19',
  minute: '*/15',
  volumes: %w[stuart s.pook] # FIXME: do all users?
    .map { |u| [u, "/home/#{u}"] }
    .to_h
    .merge(rootfs: '/')
    .merge('stuart-photos': '/home/stuart/photos')
    .map { |name, source| [name, source: source] }.to_h,
)

CfgHelper.attributes(
  %w[syncthing users stuart],
  rw: {
    'Syncthing' => 'Syncthing',
    'photos' => 'photos',
  },
)
