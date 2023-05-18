python %SUMO_HOME%\tools\generateParkingAreaRerouters.py ^
-a parking.add.xml ^
-n osm.net.xml ^
--max-number-alternatives 5 ^
--max-distance-alternatives 200 ^
--min-capacity-visibility-true 100 ^
--max-distance-visibility-true 50 ^
-o rerouter.add.xml
