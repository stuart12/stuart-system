name = 'gnucash'
return unless CfgHelper.activated? name

api_key = CfgHelper.secret([name, 'alphavantage', 'api_key'])

template '/etc/gnucash/environment.local' do
  source 'ini.erb'
  variables(
    comment: '#',
    sections: {
      Variables: {
        ALPHAVANTAGE_API_KEY: api_key,
      },
    },
  )
  mode 0o644
  owner 'root'
end

package 'dconf-editor'
package 'gnucash'
