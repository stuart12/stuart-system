#!/bin/sh -e
# maintained by Chef

cd /proc/asound/
find -H $(find * -maxdepth 1 -type l) -name hw_params | xargs grep --with-filename rate
