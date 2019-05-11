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
# TODO: fix "Failed to create HTTP server at port 8123" error after a restart in the UI.
# (probably caused by none of the *on_remove* methods being called when the restart is triggered).
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
import signal
import sys
import os
import socket

VERSION = '0.0.1'
_LOGGER = logging.getLogger(__name__)
DOMAIN = 'tcp_listener'

import voluptuous as vol

from homeassistant.components.switch import SwitchDevice, PLATFORM_SCHEMA
# https://github.com/home-assistant/home-assistant/blob/dev/homeassistant/const.py
from homeassistant.const import CONF_PORT, CONF_HOST, CONF_NAME, CONF_STATE, STATE_ON, STATE_OFF, CONF_SWITCHES
import homeassistant.helpers.config_validation as cv

REQUIREMENTS = []

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
    _LOGGER.debug("async_setup_platform")
    cfg = config[CONF_SWITCHES]
    _LOGGER.debug("starting with config %s", cfg)

    async_add_devices([ TCPListener(hass, p.get(CONF_NAME, name), p[CONF_PORT], p[CONF_STATE]) for name, p in cfg.items() ])

class TCPListener(SwitchDevice):
    def __init__(self, hass, name, port, state):
        self._hass = hass
        self._name = name
        self._state = state
        self._port = port
        self._pid = 0
        _LOGGER.debug("new TCPListener with config %s", self)
        _LOGGER.debug("new TCPListener with methods %s", dir(self))
        self.async_on_remove(self.on_remove)

    def _switch(self, newstate):
        """Switch on or off."""
        _LOGGER.info("Switching %s to state: %s", self.name, newstate)
        return newstate == 'on'

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
        _LOGGER.debug("async turn on %s pid %d %s", self.name, self._pid, kwargs)
        if not self._pid:
            self._pid = self._listen()
        self._state = STATE_ON

    async def async_turn_off(self, **kwargs):
        _LOGGER.debug("async turn off %s pid %d %s", self.name, self._pid, kwargs)
        self._stop()

    async def async_will_remove_from_hass(self):
        _LOGGER.debug("async_will_remove_from_hass %s pid %d", self.name, self._pid)
        self._stop()

    async def on_remove(self):
        _LOGGER.debug("_on_remove %s pid %d", self.name, self._pid)
        self._stop()

    def _stop(self):
        if self._pid > 0:
            os.kill(self._pid, signal.SIGKILL)
            os.waitpid(self._pid, 0)
            self._pid = 0
        self._state = STATE_OFF

    def _listen(self):
        pid = os.fork()
        if pid != 0:
            return pid
        # file:///usr/share/doc/python3-doc/html/library/socket.html
        for res in socket.getaddrinfo(None, self._port, socket.AF_UNSPEC, socket.SOCK_STREAM, 0, socket.AI_PASSIVE):
            af, socktype, proto, canonname, sa = res
            try:
                s = socket.socket(af, socktype, proto)
            except OSError as msg:
                s = None
                continue
            try:
                s.bind(sa)
                s.listen(1)
            except OSError as msg:
                s.close()
                s = None
                continue
            break
        if s is None:
            _LOGGER.error("%s could not open socket", self.name)
            sys.exit(7)
        while True:
            conn, addr = s.accept()
            with conn:
                _LOGGER.info("%s connection from %s", self.name, addr)
        sys.exit(9)
