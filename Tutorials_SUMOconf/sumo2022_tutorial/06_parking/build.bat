python "%SUMO_HOME%\tools\randomTrips.py" -n osm.net.xml --fringe-factor 5 -p 2.108033 -o osm.passenger.trips.xml -e 3600 --vehicle-class passenger --vclass passenger --prefix veh --min-distance 300 --trip-attributes "departLane=\"best\"" --fringe-start-attributes "departSpeed=\"max\"" --allow-fringe.min-length 1000 --lanes --validate

python "%SUMO_HOME%\tools\generateParkingAreas.py" -n osm.net.xml -o parking.add.xml --random-capacity --keep-all --edge-type.remove highway.motorway,highway.motorway_link

python "%SUMO_HOME%\tools\route\addStops2Routes.py" -n osm.net.xml -r osm.passenger.trips.xml --parking-areas parking.add.xml -o parking.rou.xml --duration 3600

python "%SUMO_HOME%\tools\generateParkingAreaRerouters.py" -n osm.net.xml -a parking.add.xml -o rerouter.add.xml --opposite-visible --max-distance-alternatives 4000
