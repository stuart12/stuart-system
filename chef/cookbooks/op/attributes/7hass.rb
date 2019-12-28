CfgHelper.set_config['homeassistant'].tap do |hass|
  hass['yaml'].tap do |yaml|
    yaml['homeassistant'].tap do |homeassistant|
      homeassistant['latitude'] = 48.839548
      homeassistant['longitude'] = 2.395671
      homeassistant['elevation'] = 36
      homeassistant['unit_system'] = 'metric'
      homeassistant['auth_providers'] = [
        {
          type: 'trusted_networks',
          allow_bypass_login: true,
          trusted_networks: [
            '127.0.0.1',
            '::1',
          ],
        },
      ]
    end
    yaml['frontend'] = nil
    yaml['config'] = nil
  end
end
