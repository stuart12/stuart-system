"""
    Copyright 2018 Stuart Pook
    A sensor which reads a file of (day, month) or (day, month, year) tuples
    to indicate wheather I'm on holidays.
    The file shoud consist of lines containing two (day month) or
    three integers (day month year).

    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    https://github.com/home-assistant/home-assistant/blob/dev/homeassistant/components/binary_sensor/workday.py
"""
import asyncio
import logging
import voluptuous as vol

_LOGGER = logging.getLogger(__name__)

from datetime import datetime, timedelta

from homeassistant.components.sensor import PLATFORM_SCHEMA
# https://github.com/home-assistant/home-assistant/blob/master/homeassistant/const.py
from homeassistant.const import CONF_NAME, CONF_FILENAME, CONF_OFFSET
from homeassistant.helpers.entity import Entity
from homeassistant.components.binary_sensor import BinarySensorDevice
import homeassistant.helpers.config_validation as cv

DEFAULT_NAME = 'On Holidays Sensor'
DEFAULT_OFFSET = 0

PLATFORM_SCHEMA = PLATFORM_SCHEMA.extend({
    vol.Required(CONF_FILENAME): cv.isfile, # https://www.home-assistant.io/developers/code_review_platform/
    vol.Optional(CONF_NAME, default=DEFAULT_NAME): cv.string,
    vol.Optional(CONF_OFFSET, default=DEFAULT_OFFSET): vol.Coerce(int),
})

@asyncio.coroutine
def async_setup_platform(hass, config, async_add_devices, discovery_info=None):
    sensor_name = config.get(CONF_NAME)
    hours_offset = config.get(CONF_OFFSET)
    filename = config.get(CONF_FILENAME)
    async_add_devices([OnHolidaysSensor(hours_offset, filename, sensor_name)], True)

@asyncio.coroutine
def async_fetch_state(filename, hours_offset):
    now = datetime.today() + timedelta(hours=hours_offset)
    tag = "%d-%02d-%02d" % (now.year, now.month, now.day)
    with open(filename) as holidays:
        for ln, line in enumerate(holidays, 1):
            c = line.split('#')[0].split()
            try:
                if len(c) > 1 and now.day == int(c[0]) and now.month == int(c[1]) and (len(c) == 2 or int(c[2]) == now.year):
                    _LOGGER.info("%s:%d: %s is a holiday", filename, ln, tag)
                    return True
            except ValueError as ex:
                _LOGGER.warn("%s:%d bad integer: %s", filename, ln, ex)

    _LOGGER.info("%s: %s not a holiday", filename, tag)
    return False

class OnHolidaysSensor(BinarySensorDevice):

    def __init__(self, hours_offset, filename, sensor_name):
        """Initialize the sensor."""
        self._name = sensor_name
        self._hours_offset = hours_offset
        self._filename = filename
        self._state = None

    @property
    def name(self):
        """Return the name of the sensor."""
        return self._name

    @property
    def is_on(self):
        _LOGGER.debug("return state: %s", self._state)
        return self._state

    @property
    def state_attributes(self):
        """Return the attributes of the entity."""
        return {
            CONF_OFFSET: self._hours_offset,
            CONF_FILENAME: self._filename,
        }

    @asyncio.coroutine
    def async_update(self):
        # https://www.home-assistant.io/developers/asyncio_working_with_async/
        self._state = yield from async_fetch_state(self._filename, self._hours_offset)
