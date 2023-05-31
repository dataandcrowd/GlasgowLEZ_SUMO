## Vehicles and Pedestrians

Reference: https://www.youtube.com/watch?v=Mh4WnY4KY4Y

### 1. Generate the network file (glasgow.net.xml) using the netconvert
netconvert --osm-files glasgow.osm -o glasgow.net.xml --junctions.join --roundabouts.guess --osm.elevation --tls.guess --osm.sidewalks 

### 2. Import polygons from OSM-data and produces a sumo-polygon file
polyconvert --net-file glasgow.net.xml --osm-files glasgow.osm --type-file typemap.xml -o glasgow.poly.xml 

### 3. generate the pedestrian traffic demand
python randomTrips.py -n glasgow.net.xml -r bus_routes.rou.xml  -o bus_trips.xml -e 600 -p 30 --vehicle-class bus --trip-attributes="accel=\"0.8\""
python randomTrips.py -n glasgow.net.xml -r truck_routes.rou.xml  -o truck_trips.xml -e 600 -p 15 --vehicle-class truck --trip-attributes="color=\"179,223,183\""
python randomTrips.py -n glasgow.net.xml -r delivery_routes.rou.xml  -o delivery_trips.xml -e 600 -p 30 --vehicle-class delivery --trip-attributes="color=\"115,211,230\""
python randomTrips.py -n glasgow.net.xml -r passenger_routes.rou.xml  -o passenger_trips.xml -e 600 -p 0.1 --vehicle-class passenger --trip-attributes="color=\"255,255,255\""
python randomTrips.py -n glasgow.net.xml -r trailer_routes.rou.xml  -o trailer_trips.xml -e 600 -p 150 --vehicle-class trailer --trip-attributes="color=\"223,179,180\" accel=\"0.5\""
python randomTrips.py -n glasgow.net.xml -r ped_routes.rou.xml  -o ped_trips.xml -e 600 -p 5 --pedestrians


