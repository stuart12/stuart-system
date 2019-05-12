# A Home Assistant component that listens on a TCP port.
# This code was tested with hass version 0.92.2 and written for the
# Android App Easer https://me.ryey.icu/Easer/en/ and its TCP Trip Event.
#
# This component can be configured in your HomeAssistant configuration.yaml:
#
# switch:
#   - platform: tcp_listener
#     switches:
#       noisy_telephone:
#         port: 20568
#         name: Noisy Telephone
#       quiet_telephone:
#         port: 20569
#         name: Quiet Telephone
#
# TODO: fix bugs in async & asyncio usage (this is my first async code).
# TODO: understand async_will_remove_from_hass and async_on_remove
#
# Copyright (c) 2019 Stuart Pook (http://www.pook.it/)
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import logging
import asyncio

VERSION = '0.0.2'
_LOGGER = logging.getLogger(__name__)
DOMAIN = 'tcp_listener'

import voluptuous as vol

from homeassistant.components.switch import SwitchDevice, PLATFORM_SCHEMA
# https://github.com/home-assistant/home-assistant/blob/dev/homeassistant/const.py
from homeassistant.const import CONF_PORT, CONF_NAME, CONF_STATE, STATE_ON, STATE_OFF, CONF_SWITCHES
import homeassistant.helpers.config_validation as cv

REQUIREMENTS = [] # needed?

# https://gist.github.com/ispiropoulos/90a5f215e71f4dde635e3e3407fb5804
SWITCH_SCHEMA = vol.Schema({
    vol.Optional(CONF_NAME): cv.string,
    vol.Required(CONF_PORT): cv.positive_int,
    vol.Optional(CONF_STATE, default=STATE_OFF): cv.boolean,
})

PLATFORM_SCHEMA = PLATFORM_SCHEMA.extend({
    vol.Required(CONF_SWITCHES): vol.Schema({cv.slug: SWITCH_SCHEMA}),
})

async def async_setup_platform(hass, config, async_add_devices, discovery_info=None):
    cfg = config[CONF_SWITCHES]
    _LOGGER.debug("starting with config %s", cfg)
    async_add_devices([ TCPListener(hass, p.get(CONF_NAME, name), p[CONF_PORT], p[CONF_STATE]) for name, p in cfg.items() ])

class TCPListener(SwitchDevice):
    def __init__(self, hass, name, port, state):
        self._hass = hass
        self._name = name
        self._state = state
        self._port = port
        self._server = None
        _LOGGER.debug("new TCPListener with config %s", self)
        self.async_on_remove(self.on_remove) # is this ever called?

    @property
    def name(self):
        """Return the name of the switch."""
        return self._name

    @property
    def is_on(self):
        """Return true if device is on."""
        return self._state == STATE_ON

    # https://github.com/home-assistant/home-assistant/blob/dev/homeassistant/components/switch/light.py

    async def async_turn_on(self, **kwargs):
        _LOGGER.debug("async_turn_on %s:%d", self.name, self._port)
        self._state = STATE_ON
        await self.async_listen()

    async def async_turn_off(self, **kwargs):
        _LOGGER.debug("async_turn_off %s:%d", self.name, self._port)
        self._stop()

    async def async_stop(self):
        _LOGGER.debug("async_stop %s:%d", self.name, self._port)
        self._stop()

    async def async_will_remove_from_hass(self): # is this ever called?
        _LOGGER.debug("async_will_remove_from_hass %s:%d", self.name, self._port)
        # https://git.edevau.net/Ede_Vau/home-assistant/commit/5c3a4e3d10c5b0bfc0d5a10bfb64a4bfcc7aa62f?lang=en-US
        await super().async_will_remove_from_hass()
        await self.async_stop()

    async def on_remove(self): # is this ever called?
        _LOGGER.debug("_on_remove %s:%d", self.name, self._port)
        self._stop()

    def _stop(self):
        self._state = STATE_OFF
        if self._server:
            self._server.close()
            self._server = None

    async def handle_connection(self, reader, writer):
        address = writer.get_extra_info('peername')
        _LOGGER.debug('handle_connection {}:{} from {}:{}'.format(self.name, self._port, *address))
        writer.close()

    async def async_loop(self, server):
        async with server:
            await server.serve_forever()

    async def async_listen(self):
        _LOGGER.debug("async_listen %s:%d", self.name, self._port)
        server = await asyncio.start_server(self.handle_connection, None, self._port)
        _LOGGER.debug("async_listen %s:%d on %s", self.name, self._port, server.sockets[0].getsockname())
        self._server = server
        self._hass.async_create_task(self.async_loop(server))
        _LOGGER.debug("async_listen done %s:%d", self.name, self._port)
