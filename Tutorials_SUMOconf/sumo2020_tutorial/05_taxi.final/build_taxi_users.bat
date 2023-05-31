#!/bin/bash
python "$SUMO_HOME/tools/randomTrips.py" -n net.net.xml -o persontrips.xml -e 1800 --persontrips --trip-attributes "modes=\"taxi\""
