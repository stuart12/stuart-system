return unless platform? 'raspbian'

ck = node['stuart']
cfg = ck.dig('config', 'boot', 'config') || {}

dtoverlays =
  (cfg['dtoverlay'] || {})
  .select { |_, where| where }
  .flat_map { |o, w| [w, o] }
  .each_slice(2) # https://stackoverflow.com/questions/23659947/ruby-convert-array-to-hash-preserve-duplicate-key
  .with_object(Hash.new { |h, k| h[k] = [] }) { |(k, v), hash| hash[k] << v }

template '/boot/config.txt' do
  variables(
    dtparam: cfg['dtparam'] || {},
    dtoverlay: dtoverlays,
    options: cfg['options'] || {},
  )
  # user 'root' is on FAT
  # mode 0o644 is on FAT
end
