#!/bin/bash
python "$SUMO_HOME/tools/ptlines2flows.py" -n osm.net.xml -e 5400 -p 600 --random-begin --seed 42 --ptstops osm_stops.add.xml --ptlines osm_ptlines.xml -o osm_pt.rou.xml --ignore-errors --vtype-prefix pt_
python "$SUMO_HOME/tools/randomTrips.py" -n osm.net.xml --seed 42 --fringe-factor 1 -p 1 -r osm.pedestrian.rou.xml -o osm.pedestrian.trips.xml -e 3600 --vehicle-class pedestrian --persontrips --prefix ped --trip-attributes 'modes="public"' --additional-files osm_stops.add.xml,osm_pt.rou.xml
python "$SUMO_HOME/tools/randomTrips.py" -n osm.net.xml --seed 42 --fringe-factor 5 -p 2.600414 -r osm.passenger.rou.xml -o osm.passenger.trips.xml -e 3600 --vehicle-class passenger --vclass passenger --prefix veh --min-distance 300 --trip-attributes 'departLane="best"' --validate
