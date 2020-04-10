return unless CfgHelper.activated? 'firefox'

# see /usr/lib/firefox/browser/defaults/syspref/firefox.js
locked = CfgHelper.attributes(
  %w[firefox locked],
  'browser.tabs.warnOnClose': false,
  'browser.aboutConfig.showWarning': false,
  'privacy.userContext.newTabContainerOnLeftClick.enabled': true,
  'browser.newtabpage.enhanced': true,
  # rubocop:disable Layout/LineLength
  'browser.uiCustomization.state': '{"placements":{"widget-overflow-fixed-list":["_contain-facebook-browser-action","https-everywhere_eff_org-browser-action","developer-button"],"nav-bar":["back-button","forward-button","stop-reload-button","home-button","bookmarks-menu-button","urlbar-container","privatebrowsing-button","new-window-button","downloads-button","sidebar-button","forget-me-not_lusito_info-browser-action","addon_darkreader_org-browser-action"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["personal-bookmarks"]},"seen":["developer-button","forget-me-not_lusito_info-browser-action","_contain-facebook-browser-action","addon_darkreader_org-browser-action","https-everywhere_eff_org-browser-action"],"dirtyAreaCache":["nav-bar","toolbar-menubar","TabsToolbar","PersonalToolbar","widget-overflow-fixed-list"],"currentVersion":16,"newElementCount":3}',
  # rubocop:enable Layout/LineLength
)

suffix = ''
name = "firefox#{suffix}"
paquet name

template "/etc/#{name}/chef.js" do
  source 'firefox.js.erb'
  variables(locked: locked)
  mode 0o644
  owner 'root'
end

extensions = "/usr/lib/#{name}/distribution/extensions"
directory extensions do
  owner 'root'
  mode 0o755
end

# to find the ID see extensions.webextensions.uuid in about:config
{
  '@contain-facebook' => 3_519_841,
  'forget-me-not@lusito.info' => 3_468_924,
  'https-everywhere@eff.org' => 3_442_258,
  'addon@darkreader.org' => 3_528_805,
}.each do |id, url|
  remote_file ::File.join(extensions, "#{id}.xpi") do
    source "https://addons.mozilla.org/firefox/downloads/file/#{url}/"
    owner 'root'
    mode 0o644
  end
end

file '/etc/firefox/local-settings.js' do
  action :delete
end
