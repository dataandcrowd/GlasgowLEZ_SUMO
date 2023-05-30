## Vehicles and Pedestrians

Reference: https://www.youtube.com/watch?v=Mh4WnY4KY4Y

### 1. Generate the network file (glasgow.net.xml) using the netconvert
netconvert --osm-files map.osm -o glasgow.net.xml --junctions.join --roundabouts.guess --osm.elevation --tls.guess

### 2. Import polygons from OSM-data and produces a sumo-polygon file
polyconvert --net-file glasgow.net.xml --osm-files map.osm --type-file typemap.xml -o glasgow.poly.xml --xml-validation never

### 3. generate the pedestrian traffic demand
python randomTrips.py --n glasgow.net.xml -r cars.rou.xml -e 1000 -l --validate never
<!--
python randomTrips.py -n glasgow.net.xml -r cars.rou.xml -t "type=\"car\" departSpeed=\"max\" departLane=\"best"" -c passenger --additional-files car.add.xml -p 1.4 -e 1000 -l
-->

python randomTrips.py --n glasgow.net.xml -r passenger_routes.rou.xml  -o passenger_trips.xml -e 600 -p 0.1 --vehicle-class passenger --trip-attributes="color=\"255,255,255\""

