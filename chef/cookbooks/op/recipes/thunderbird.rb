name = 'thunderbird'
return unless CfgHelper.activated? name
paquet name
paquet 'webext-dav4tbsync'

# https://unix.stackexchange.com/questions/190258/how-to-add-a-thunderbird-addon-globally
extensions = "/usr/lib/#{name}/extensions"
%w[
  cardbook@vigneau.philippe
].each do |plugin|
  remote_file ::File.join(extensions, plugin + '.xpi') do
    source "https://addons.thunderbird.net/thunderbird/downloads/latest/cardbook/#{plugin}"
    owner 'root'
    mode 0o644
    action :delete
  end
end
