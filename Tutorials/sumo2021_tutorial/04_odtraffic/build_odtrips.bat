%SUMO_HOME%\bin\od2trips -n tazgrid.add.xml --tazrelation-files od.xml --ignore-vehicle-type -o odtrips.xml
%SUMO_HOME%\bin\duarouter -n osm.net.xml -r odtrips.xml --ignore-errors --write-trips -o odtrips_valid.xml
