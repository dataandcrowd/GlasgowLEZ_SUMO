extensions [gis csv table nw ]                ; GIS extension for NetLogo to import GIS shapefiles, csv extension to import csv files, table to create tables for variables, nw to create road networks from shapefiles

globals [
  pollution-data
  area
  roads
  streets
  mean-pm10
  back_pm10_sample
  pm10-back pm10-road pm10-others
  t_sajik t_jahamoon t_daesagwan t_daehak t_jongno
  t_dongho t_ns2ho t_soparo t_saemunan t_ssm
  v_sajik v_jahamoon v_daesagwan v_daehak v_jongno
  v_dongho v_ns2ho v_soparo v_saemunan v_ssm
  Jongno_p Jung_p
  JongnoKerb_p Samil_p Sejong_p Pirum_p Yulgok_p
  Drivers_p Walkers_p
  d_nearroad e_nearroad
  d_farroad e_farroad
]

breed [nodes node]                           ; Breeds allows the modeller to easily ask some sets of agents to run commands or otherwise take actions
breed [area-labels area-label]
breed [buildings building]
breed [busstops busstop]
breed [cars car]
breed [employees employee]
breed [drivers driver]
                                             ; XXX-own is the attributed tied to each entity group
links-own [                                  ; For instance, road-name, is-road?, max-spd, Daero?, and weight appear in the attribute table of each road segment
  road-name
  is-road?
  max-spd
  Daero?
  weight
]

patches-own [
  is-research-area?
  is-endpoint?
  intersection
  mybuilding
  building_info
  dilution
  countdown
  dong-name
  dong-code
  road_buffer
  pm10
  pm10_indoor
  centroid? ;;is it the centroid of a building?
  id   ;;if it is a centroid of a building, it has an ID that represents the building
  b_entrance ;;nearest vertex on road. only for centroids.
]

nodes-own [
  name
  dong_code
  endpoint?
  line-start
  line-end
  auto?
  green-light?
  intersection?
  b_entrance?
  dist-original  ;;distance from original point to here
]

busstops-own [
 bus_stop ;; Seoul Metro has lines from 1 to 9
]

buildings-own [
 close-to-road?
 ;count-employees
]

cars-own [
  speed
  fueltype
  tyre-wear
  brake-wear
  surface-wear
  total-emission
  origin ;;a vertex. where the vehicle begins the trip
  destination ;; allocated destination
  myoffice
  goal  ;;the b_entrance of the destination on the road
  path-work ;; an agentset containing nodes to visit in the shortest path
  path-home
  nodes-remaining
  current
  to-node
  myroad
  current-link
  district_name district_code
  link-counter   ;counter for distance along path
  direction      ;+1 work to work and -1 for to home
  time-at-work   ; how long to spend at work
  random-car     ; work like venice model, or go home to work and back
  parked         ; parked cars don't interfere with other traffic
  owner
  health
  leave-home-hour
  leave-home-mins
  unwell_history
  work-near-roads?
]


employees-own [
  origin ;;a vertex. where the vehicle begins the trip
  origin_patch
  myhome
  myoffice
  goal  ;;the b_entrance of the destination on the road
  current
  Heuristic
  arrived?
  time-at-work   ; how long to spend at work
  direction
  arrive-tick
  leave-home-hour
  leave-home-mins
  work-near-roads?
  health
  unwell_history
]

drivers-own [
  commute_method
  my_car
  age
  health
  ;work-near-roads?
]

;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ca  ; clear everything
  set-gis
  add-labels
  activate-links
  set-signals
  set-random-cars
  set-resident-cars
  set-resident-driver
  set-incoming-traffic
  set-subway-commuters
  set-OD
  set-path-node
  set-path-link
  set-road-ends
  set-pm10
  set-pm10-others
  ask cars with [not random-car] [to-work-setup] ;; We setup the OD for resident vehicles
  reset-ticks

end

;;---------------------------------------------------------
to go

;;---This section is a list of global variables that run in the Behaviorspace or on the HPC-----
  set back_pm10_sample precision ([pm10] of patch 81 91) 2
  set Jongno_p     precision ([pm10] of patch 88 94) 2
  set Jung_p       precision ([pm10] of patch 38 68) 2
  set JongnoKerb_p precision ([pm10] of patch 105 95) 2
  set Samil_p      precision ([pm10] of patch 77 77) 2 ;"Samil-daero"
  set Sejong_p     precision ([pm10] of patch 43 112) 2 ;"Sejong-daero"
  set Pirum_p      precision ([pm10] of patch 22 148) 2 ;"Pirun-daero"
  set Yulgok_p     precision ([pm10] of patch 124 117) 2 ;"Daehak-ro"
  set Drivers_p    precision ((count cars with [not random-car and health < 100] /
                               count cars with [not random-car]) * 100) 3
  set Walkers_p    precision ((count(employees with [health < 100]) / count employees) * 100) 3
  set mean-pm10    precision mean [pm10] of patches with [is-research-area? = true] 2
;;---------------------------------------------------------------------
;;-- Stop condition--
  if (export-raster = "no" and (ticks + 1) >= 127740) or (export-raster = "yes" and (ticks + 1) >= 1442) [stop]

;;--This section looks a bit messy but it makes cars to run differently on weekends.
  ask cars [
    let is-weekend? item 6 table:get pm10-road (ticks + 1)
    let what-time?  item 1 table:get pm10-road (ticks + 1)
     let hours item 1 table:get pm10-back (ticks + 1)
    let minutes item 4 table:get pm10-back (ticks + 1)
    let weekday? item 5 table:get pm10-back (ticks + 1)
    let travel-hours what-time? >= (8 + random 2) and what-time? < 22
    ifelse (random-car)[move speed]
      [ if is-weekend? = false and weekday? != "Mon" [travel speed]
        if is-weekend? = false and weekday? = "Mon" and hours = 6 and minutes = 59 [to-work-setup set time-at-work 540 + random 61]
        if is-weekend? = false and weekday? = "Mon" and hours >= 7  [travel speed]
        if is-weekend? = false and weekday? = "Mon" and hours >= 7 and minutes = 5 and parked [park]
        if (is-weekend? = true and awareness = "no" and travel-hours) [move speed] ;; move resident cars on weekends only when awareness off
        if (is-weekend? = true and awareness = "yes" and travel-hours and health >= 100) [move speed] ;; take rest when awareness on
        if (is-weekend? = true and awareness = "yes" and travel-hours and health < 100)  [move-to origin to-work-setup] ;; take rest when awareness on
        if (is-weekend? = true and what-time? >= 23) [move-to origin to-work-setup] ] ;; Flying cars may appear.
                                                                 ;; They are just heading home without using the road links.
  ]

  speed-up
  set-signal-colours
  meet-traffic-lights
  drive-out-of-cbd
  add-cars
  pollute
  fadeout
  kill-cars
  add-employees
  move-employees
  move-drivers
  health-loss
  health-recovery
  validation-plot
  age-plot
  tick
  if(export-raster = "yes")[store-raster]

end


;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;

to set-gis
  ask patches [ set pcolor white ]                                     ;; set a white background
  set area  gis:load-dataset "GIS/LEZ_Extent.shp"              ;; set shapefile
  set roads gis:load-dataset "GIS/LEZ_road.shp"              ;; set road network
  let world_envelope gis:load-dataset "GIS/LEZ_road.shp" ;; set spatial extent
  gis:set-world-envelope (gis:envelope-union-of gis:envelope-of world_envelope) ;; set spatial extent


;; Assign subdistrict name to each patch
  ask patches gis:intersecting area [set is-research-area? true]
  foreach gis:feature-list-of area [vector-feature ->
 ; ask patches [if gis:intersects? vector-feature self
 ;     [ set dong-name gis:property-value vector-feature "adm_dr_nm_"
 ;       set dong-code gis:property-value vector-feature "DONG_CODE" ]
 ;]
  ]

;; Assign road info
  ask patches gis:intersecting roads [set road_buffer true ]
  ask patches with [road_buffer != true][ set road_buffer false ]


;; Assign Buildings
  let building-layer gis:load-dataset "GIS/LEZ_buildings.shp"     ;; import buildings from a GIS file
  gis:set-drawing-color 107  gis:fill building-layer 1.0               ;; colour buildings into blue
  ask patches gis:intersecting building-layer [set mybuilding true ]   ;; set the building areas as true
  ask patches with [mybuilding != true][set mybuilding false]          ;; set the non-building areas as false


;; Identify centroids and assign IDs to centroids
;; This loop is used as to assign a centroid location for each building so that the agents can set their destinations

   foreach gis:feature-list-of building-layer [ feature ->
    let centroid gis:location-of gis:centroid-of feature
    if not empty? centroid [
      create-buildings 1 [
        set xcor item 0 centroid
        set ycor item 1 centroid
        set size 0
        set centroid? true
        set building_info self
        set id gis:property-value feature "ID"
        ifelse [road_buffer] of patch-here = true [set close-to-road? true][set close-to-road? false]
    ]]]
  ask patches with [centroid? != true][set centroid? false set ID "not given"  ]


;; Create subway entrances: "s_entrances"

  let subway gis:load-dataset "GIS/busstop.shp"
  foreach gis:feature-list-of subway [ vector-feature ->
    foreach gis:vertex-lists-of vector-feature [ vertex ->
      foreach vertex [ point ->
        let location gis:location-of point
        if not empty? location [
         create-busstops 1  [
            set xcor item 0 location
            set ycor item 1 location
            set shape "flag"
            set size 3
            set bus_stop gis:property-value vector-feature "name"
            set color one-of base-colors
            ;if Line = 1 [ set color blue ]
            ;if Line = 2 [ set color lime ]
            ;if Line = 3 [ set color orange ]
            ;if Line = 4 [ set color sky ]
            ;if Line = 5 [ set color magenta ]
  ]]]]]

  ask busstops [
    if count busstops-here > 1 [
      ask other busstops-here [ die ] ]]



;; Create turtles representing the nodes. Create links to connect them
  foreach gis:feature-list-of roads [ vector-feature ->
    let first-vertex gis:property-value vector-feature "UP_FROM_NO"
    let last-vertex gis:property-value vector-feature "UP_TO_NO"

    foreach  gis:vertex-lists-of vector-feature [ vertex ->
      let previous-node nobody

      foreach vertex [ point ->
        let location gis:location-of point
        if not empty? location
        [ create-nodes 1 [
            set xcor item 0 location
            set ycor item 1 location
            set size 0.05
            set shape "circle"
            set color one-of base-colors
            set hidden? false
            set line-start first-vertex
            set line-end last-vertex

            ifelse previous-node = nobody
              []
              [create-link-with previous-node] ; create link to previous node
               set previous-node self]
        ]
  ] ; end of foreach vertex
  ] ; end of foreach  gis:vertex-lists-of vector-feature
  ] ; end of foreach gis:feature-list-of roads


  ;;delete duplicate vertices
  ;;(there may be more than one vertice on the same patch due to reducing size of the map).
  ;;therefore, this map is simplified from the original map.
    ask nodes [
      if count nodes-here > 1 [
      ask other nodes-here  [
        ask myself [create-links-with other [link-neighbors] of myself]
        die]]
     ]

  ;;find nearest node to become b_entrance
  ask patches with [centroid? = true][
    set b_entrance min-one-of nodes in-radius 200 [distance myself]
    ask b_entrance [set b_entrance? true]]
  ask patches with [centroid? = false][ask nodes [set b_entrance? false]]

end

;;--4daemoon represents four main gates built back in the previous Kingdom of Chosun.--;;
to draw-4daemoon
  gis:set-drawing-color [ 229 255 204]    gis:fill area 0 ;;RGB color
  gis:set-drawing-color [  64  64  64]    gis:draw area 1
end

to draw-map
  ;import-drawing "GIS/map.png"
end

to add-labels
foreach gis:feature-list-of area [vector-feature ->
    let centroid gis:location-of gis:centroid-of vector-feature
       if not empty? centroid
      [ create-area-labels 1
        [ set xcor item 0 centroid
          set ycor item 1 centroid
          set size 0
          set label-color blue
          set label gis:property-value vector-feature "adm_dr_nm_"
      ]]]
  ask nodes [set dong_code [dong-code] of patch-here]

end

to activate-links
  ask links [
    set is-road? true
    let way list [line-start] of end1 [line-end] of end2
    let daero ["Jahamun-ro"  "Sajik-ro"  "Samil-daero"  "Yulgok-ro"  "Toegye-ro" "Saemunan-ro 3-gil" "Jangchungdan-ro"
      "Taepyeong-ro"  "Sejong-daero"  "Jong-ro"  "Eulji-ro"  "Seosomun-ro" "Donhwamun-ro" "Sejong-daero 23-gil"]

    foreach gis:feature-list-of roads [ vector-feature-sub ->
      let mspeed gis:property-value vector-feature-sub "MAX_SPD"
      let vector-start gis:property-value vector-feature-sub "UP_FROM_NO"
      let vector-end gis:property-value vector-feature-sub "UP_TO_NO"
      let start-end list vector-start vector-end
      let end-start list vector-end vector-start

      if way = start-end [set road-name gis:property-value vector-feature-sub "ROAD_NAME_"]
      if road-name = one-of daero [set Daero? true]
      if road-name = 0 or road-name = "" [set road-name [name] of end2 ]
      set max-spd read-from-string mspeed
         ]
  ]
end

to set-signals
  ask nodes [
    ifelse count my-links > 2      ; We arbitrarily set the traffic lights where the link intersections are more than 2
      [set size 3                  ; There might be more in reality
       set intersection? true
       set auto? random 11         ; We set the timer
    ]
      [set color grey]
  ]

  ask nodes with [intersection? = true][                          ; As the timer ticks down from 10 to 0
    if auto? >= 5 [set color green set green-light? true]         ; If the number is 5 or more then the traffic light is green
    if auto? <  5 [set color red set green-light? false]          ; If the number is less than 5 the light is red
    set pcolor black + 5
    ask neighbors [set pcolor black + 4]
    ask patches with [pcolor = black + 4] [set intersection true]
  ]
end

;;- We set the road endpoints (or entry points) for the non-resident inbound vehicles.
to set-road-ends
  let endpoints0 map node [5465 5463 5464 5451 5452 5798 5797 5685 5690 6745 6753 5653 5651 5652 6687 6679]
  let endpoints filter is-node? endpoints0

 foreach endpoints [ep ->
    ask ep [set endpoint? true ask patch-here [set is-endpoint? true ]]
]
  ask nodes with [endpoint? != true][set endpoint? false]
  ask patches with [is-endpoint? = true][ask neighbors [set is-endpoint? true]]
  ask patches with [is-endpoint? != true][set is-endpoint? false]


end


to set-random-cars
  set-default-shape cars "car"
  create-cars 50 [ ;; random-cars
    set parked false
    set random-car true
    set size 2
    set speed 0
    set destination nobody
    set origin one-of nodes move-to origin
            ]

  ask n-of (int(.7 * count cars)) cars [set fueltype "Gasoline"]   ; 70% of the vehicles in Seoul CBD owns gasoline (unleaded) cars
  ask cars with [fueltype != "Gasoline"][set fueltype "Diesel" ]   ; the next majority is Diesel
end



to set-path-node
    ask cars [
    ; Randomly choose a target node to walk to
    let target [goal] of self
    ;print target
    if target != nobody [
      ; Remember the starting node
      set current one-of nodes-here
      ; Define a path variable from the current node- take all but
      ; the first item (as first item is current node)
      let path nobody
      ask links [ set weight link-length ]
      ask current [
        set path but-first nw:turtles-on-weighted-path-to target weight
      ]

      ; Indicate the end node
      ask last path [
        set color [color] of self
        set b_entrance? true
        set size 0.5 ]

      let path-work0 lput path path-work ;; assign all the nodes that leads to the destination node
      set path-work item 0 path-work0
      set path-work fput origin path-work
      set to-node first path ;; or can code as ---> item 0 item 0 path-work

    ]

    set nodes-remaining length [path-work] of self
    set current-link link [who] of [current] of self [who] of [to-node] of self
    face to-node

    let points n-values [nodes-remaining] of self [x -> ([nodes-remaining] of self - 1) - x]
    foreach points [ x ->
    set path-home lput item x [path-work] of self path-home
    ]
    set path-home lput origin path-home
   ]
end

to set-path-link
  ask cars [
    let vertex0 path-work
    let vertex1 remove-item 0 path-work

    let imsi0 []
    foreach vertex0 [ x ->
      let element [who] of x
      set imsi0 lput element imsi0
    ]
    let imsi00 bl imsi0
    let imsi1 []
    foreach vertex1 [ x ->
      let element [who] of x
      set imsi1 lput element imsi1
    ]
   set myroad (map link imsi00 imsi1)
  ]
end



to set-pm10
  ; Import daily pollution
  let p0 csv:from-file "GIS/jongno_pm10.csv"
  let poll-value remove-item 0 p0  ;;remove headers in the csv file
  let rep 0  ;; loop

  set pm10-back table:make
  set pm10-road table:make

  foreach poll-value [poll ->
    if item 1 poll = "Back" [
    let counter item 0 poll ;; counter
    let date/hour list (item 2 poll)(item 3 poll) ;; add date and place
    let value lput item 4 poll date/hour
    let pm10_ lput item 5 poll value
    let minute lput item 6 poll pm10_
    let wdays lput item 7 poll minute
    let isweekend lput item 8 poll wdays
    table:put pm10-back counter isweekend
  ]
    if item 1 poll = "Road" [
    let counter item 0 poll ;; counter
    let date/hour list (item 2 poll)(item 3 poll) ;; add date and place
    let value lput item 4 poll date/hour
    let pm10_ lput item 5 poll value
    let minute lput item 6 poll pm10_
    let wdays lput item 7 poll minute
    let isweekend lput item 8 poll wdays
    table:put pm10-road counter isweekend
  ]
  ]
  set rep rep + 1

  ask patches with [is-research-area? = true and not road_buffer]
    [set pm10 (item 2 table:get pm10-back 1) + random-float (item 3 table:get pm10-back 1) set pm10_indoor nobody]

  ask patches with [is-research-area? = true and road_buffer = true]
    [set pm10 (item 2 table:get pm10-road 1) + random-float (item 3 table:get pm10-road 1)]

end


to set-pm10-others
 ; Import daily pollution
  let p0 csv:from-file "GIS/other_pm10.csv"
  let poll-value remove-item 0 p0  ;;remove headers in the csv file
  let rep 0  ;; loop

  set pm10-others table:make

  foreach poll-value [poll ->
    if item 1 poll = "Mix" [
    let counter item 0 poll ;; counter
    let date/hour list (item 2 poll)(item 3 poll) ;; add date and place
    let value lput item 4 poll date/hour
    let #sd lput item 5 poll value
    let minute lput item 6 poll #sd
    let wdays lput item 7 poll minute
    let isweekend lput item 8 poll wdays
    table:put pm10-others counter isweekend
  ]]

  ask patch max-pxcor max-pycor
  [set pm10 (item 2 table:get pm10-others 1) + random-float (item 3 table:get pm10-others 1)]
end



to set-resident-cars
  let vehicle csv:from-file "GIS/Seoul_Vehicle_sample.csv"
  let rawheader item 0 vehicle
  let carTT remove-item 0 rawheader
  let carstat remove-item 0 vehicle

  let districtCar table:make
  let districtadminCode table:make


  foreach carstat [ code ->
    let gasdiesel list (item 2 code)(item 3 code)
    let total lput item 4 code gasdiesel
    table:put districtCar item 0 code total
    table:put districtadminCode item 0 code item 1 code
  ]


    foreach table:keys districtCar [ v ->
    let carGroupID 0
    foreach table:get districtCar v [ xx ->
      create-cars xx [ ;; resident car ratio
        set random-car false
        set time-at-work 540 + random 61
        setupCarGroup carGroupID
        set size 2
        set district_code v
        set district_name table:get districtadminCode v
        set shape "car"
        set origin one-of nodes with [dong_code = [district_code] of myself]
        set destination nobody
        set health 300
        set unwell_history false
        set leave-home-hour 7
        set leave-home-mins random 40
      ]
      set carGroupID carGroupID + 1
    ]]

  ask cars [ifelse origin != nobody [move-to origin]
    [set origin one-of nodes with [dong_code = 1101054]
    move-to origin
    ]
  ]
end


to setupCarGroup [Car_ID]
  if Car_ID = 0 [set fueltype "Gasoline" set color green]
  if Car_ID = 1 [set fueltype "Diesel" set color black + 1]
  if Car_ID = 2 [set fueltype "LPG" set color blue + 2]
end



to set-OD   ;; Decomposing matrix
  let odcar csv:from-file "GIS/od_car.csv"
  let rawheader item 0 odcar
  let destinationNames remove-item 0 rawheader
  let ODMat remove-item 0 odcar

  let ODMatrix table:make
  foreach ODMat [ origin-chart ->
    let number remove-item 0 origin-chart
    table:put ODMatrix item 0 origin-chart number
  ]

  foreach table:keys ODMatrix [originName ->
    let matrix-loop 0
    let Num count cars with [district_code = originName]
    let totalUsed 0
    let number 0

  foreach table:get ODMatrix originName [ percent ->
      let newDestination item matrix-loop destinationNames
      ifelse (newDestination != 1102060)
          [set number precision (percent * Num) 0 set totalUsed totalUsed + number]
          [set number Num - totalUsed]

      let carsRemaining cars with [district_code = originName and destination = nobody]

      ask n-of number carsRemaining [
        set destination one-of patches with [dong-code = newDestination and centroid? = true and intersection != true]
        set myoffice [building_info] of destination
        set goal [b_entrance] of destination
        ifelse [close-to-road?] of myoffice = true [ set work-near-roads? true ][ set work-near-roads? false ]
        set path-work []
        set path-home []
        set myroad []

        while [goal = origin] [
          set destination one-of patches with [dong-code = newDestination and centroid? = true and intersection != true]
          set goal [b_entrance] of destination
          set myoffice [building_info] of destination
          ifelse [close-to-road?] of myoffice = true [ set work-near-roads? true ][ set work-near-roads? false ]
        ]
       ]

     set matrix-loop matrix-loop + 1
    ]
output-type totalused output-type " " output-type Num output-type " " output-print originName
  ]

  ;;;; Kill cars for the time being
  ask cars with [destination = nobody][die]
  type (word "Cars not able to find their destinations were killed for the time being" "\n"
    "Flying cars might appear on Sat&Sun Nights: Simplifying the 'head home' procedure after a day trip")
  ;;;; Change vehicle's goal if loaded at endpoints
  ask cars with [origin = [endpoint?] of nodes ][move-to one-of nodes in-radius 10 with [endpoint? = false] set endpoint? nodes-here]
  ask cars [
    if goal = [endpoint?] of nodes [ set goal one-of nodes with [endpoint? = false]
  ]]
end

to to-work-setup
  ;initialisation
  set parked false
  set to-node goal
  set current-link item 0 myroad
  ifelse  ([end1] of current-link = origin) [set to-node [end2] of current-link]
                                            [set to-node [end1] of current-link]
  face to-node
  set link-counter 0
  set direction 1
end


to to-home-setup
  ;initialisation
  set parked false
  set to-node origin
  set current-link last myroad
  ifelse  ([end1] of current-link = goal)   [set to-node [end2] of current-link]
                                            [set to-node [end1] of current-link]
  face to-node
  set link-counter (length myroad) - 1
  set direction -1
end


to set-resident-driver
  ask cars with [not random-car] [
    let c self
    hatch-drivers 1 [
     set shape "person business"
     set commute_method "Drive"
     set my_car c
     set age 25 + random 60
     set health 300
     ;set work-near-roads? [work-near-roads?] of c
  ]

  let my_driver item 0 [self] of drivers-on patch-here
  if [my_car] of my_driver = c [set owner my_driver]]
  ;ask drivers with [work-near-roads? != true][set work-near-roads? false]
  ask drivers [set hidden? true ]
end



to set-subway-commuters
  create-employees no-of-employees [
    set size 2
    set shape "person business"
    set arrived? false
    set origin one-of busstops
    set origin_patch [patch-here] of origin
    set myhome (patch max-pxcor max-pycor)
    set goal nobody
    set Heuristic 0
    set current 0
    set direction 0
    set arrive-tick 0
    set leave-home-hour nobody
    set leave-home-mins random 60
    set health 300
    ]

  ask n-of (count employees * .9) employees [
    set leave-home-hour (6 + random 3)
  ]

  ask employees
  [
    move-to patch max-pxcor max-pycor
    if leave-home-hour = nobody [ set leave-home-hour (8 + random 4) ]
    let p 0
    ask origin [set p one-of buildings in-radius 20 with [ is-research-area? = true]]
    set myoffice p
    set goal [patch-here] of p
    set work-near-roads? [close-to-road?] of myoffice = true
  ]

end


to set-incoming-traffic
  let p0 csv:from-file "GIS/traffic_calibration.csv"
  let traff-value remove-item 0 p0  ;;remove headers in the csv file

  set t_sajik table:make
  set t_jahamoon table:make
  set t_daesagwan table:make
  set t_daehak table:make
  set t_jongno table:make
  set t_dongho table:make
  set t_ns2ho table:make
  set t_soparo table:make
  set t_saemunan table:make
  set t_ssm table:make


  foreach traff-value [traff ->
    if item 1 traff = "A-02" [
    let counter item 0 traff ;; counter
    let date/hour list (item 2 traff)(item 3 traff) ;; add date and place
    let #count lput item 4 traff date/hour
    let weekday lput item 5 traff #count
    table:put t_sajik counter weekday
  ]

  if item 1 traff = "A-03" [
    let counter item 0 traff ;; counter
    let date/hour list (item 2 traff)(item 3 traff) ;; add date and place
    let #count lput item 4 traff date/hour
    let weekday lput item 5 traff #count
    table:put t_jahamoon counter weekday
  ]

  if item 1 traff = "A-04" [
    let counter item 0 traff ;; counter
    let date/hour list (item 2 traff)(item 3 traff) ;; add date and place
    let #count lput item 4 traff date/hour
    let weekday lput item 5 traff #count
    table:put t_daesagwan counter weekday
  ]

  if item 1 traff = "A-07" [
    let counter item 0 traff ;; counter
    let date/hour list (item 2 traff)(item 3 traff) ;; add date and place
    let #count lput item 4 traff date/hour
    let weekday lput item 5 traff #count
    table:put t_daehak counter weekday
  ]

  if item 1 traff = "A-08" [
    let counter item 0 traff ;; counter
    let date/hour list (item 2 traff)(item 3 traff) ;; add date and place
    let #count lput item 4 traff date/hour
    let weekday lput item 5 traff #count
    table:put t_jongno counter weekday
  ]

  if item 1 traff = "A-10" [
    let counter item 0 traff ;; counter
    let date/hour list (item 2 traff)(item 3 traff) ;; add date and place
    let #count lput item 4 traff date/hour
    let weekday lput item 5 traff #count
    table:put t_dongho counter weekday
  ]

  if item 1 traff = "A-21" [
    let counter item 0 traff ;; counter
    let date/hour list (item 2 traff)(item 3 traff) ;; add date and place
    let #count lput item 4 traff date/hour
    let weekday lput item 5 traff #count
    table:put t_ns2ho counter weekday
  ]

  if item 1 traff = "A-24" [
    let counter item 0 traff ;; counter
    let date/hour list (item 2 traff)(item 3 traff) ;; add date and place
    let #count lput item 4 traff date/hour
    let weekday lput item 5 traff #count
    table:put t_soparo counter weekday
  ]

  if item 1 traff = "A-14" [
    let counter item 0 traff ;; counter
    let date/hour list (item 2 traff)(item 3 traff) ;; add date and place
    let #count lput item 4 traff date/hour
    let weekday lput item 5 traff #count
    table:put t_saemunan counter weekday
  ]

  if item 1 traff = "A-16" [
    let counter item 0 traff ;; counter
    let date/hour list (item 2 traff)(item 3 traff) ;; add date and place
    let #count lput item 4 traff date/hour
    let weekday lput item 5 traff #count
    table:put t_ssm counter weekday
  ]
  ]

extra-setting
end


to extra-setting
 set v_sajik []
 let k_sajik table:keys t_sajik
 foreach k_sajik
      [triggers -> repeat 60 [
          let carcounts item 2 table:get t_sajik triggers
          set v_sajik lput carcounts  v_sajik ]]

 set v_jahamoon []
 let k_jahamoon table:keys t_jahamoon
 foreach k_jahamoon
      [triggers -> repeat 60 [
          let carcounts item 2 table:get t_jahamoon triggers
          set v_jahamoon lput carcounts  v_jahamoon ]]

 set v_daesagwan []
 let k_daesagwan table:keys t_daesagwan
 foreach k_daesagwan
      [triggers -> repeat 60 [
          let carcounts item 2 table:get t_daesagwan triggers
          set v_daesagwan lput carcounts v_daesagwan ]]

 set v_daehak []
 let k_daehak table:keys t_daehak
 foreach k_daehak
      [triggers -> repeat 60 [
          let carcounts item 2 table:get t_daehak triggers
          set v_daehak lput carcounts v_daehak ]]

 set v_jongno []
 let k_jongno table:keys t_jongno
 foreach k_jongno
      [triggers -> repeat 60 [
          let carcounts item 2 table:get t_jongno triggers
          set v_jongno lput carcounts v_jongno ]]

 set v_dongho []
 let k_dongho table:keys t_dongho
 foreach k_dongho
      [triggers -> repeat 60 [
          let carcounts item 2 table:get t_dongho triggers
          set v_dongho lput carcounts v_dongho ]]

 set v_ns2ho []
 let k_ns2ho table:keys t_ns2ho
 foreach k_ns2ho
      [triggers -> repeat 60 [
          let carcounts item 2 table:get t_ns2ho triggers
          set v_ns2ho lput carcounts v_ns2ho ]]

 set v_soparo []
 let k_soparo table:keys t_soparo
 foreach k_soparo
      [triggers -> repeat 60 [
          let carcounts item 2 table:get t_soparo triggers
          set v_soparo lput carcounts v_soparo ]]

 set v_saemunan []
 let k_saemunan table:keys t_saemunan
 foreach k_saemunan
      [triggers -> repeat 60 [
          let carcounts item 2 table:get t_saemunan triggers
          set v_saemunan lput carcounts v_saemunan ]]

 set v_ssm []
 let k_ssm table:keys t_ssm
 foreach k_ssm
      [triggers -> repeat 60 [
          let carcounts item 2 table:get t_ssm triggers
          set v_ssm lput carcounts v_ssm ]]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;GO;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to move [dist] ;;
  set current one-of nodes-here
  let dxnode distance to-node
  ifelse dxnode > dist [forward dist] [
    let nextlinks [my-links] of to-node

    ifelse count nextlinks = 1
    [ set-next-car-link current-link to-node ]
    [ set-next-car-link  one-of nextlinks with [self != [current-link] of myself] to-node]
    move dist - dxnode
    set-emission
   ]
end


to set-next-car-link [way n]
  set current-link way
  move-to n
  ifelse n = [end1] of way [set to-node [end2] of way] [set to-node [end1] of way]
  face to-node
end



to travel [dist]
  set current one-of nodes-here    ;; if "current" isn't assigned, then the vehicles will fly everywhere..
  let dxnode distance to-node

  ifelse dxnode > dist
    [forward dist]
    [
    move-to to-node
    ifelse (direction = 1  and to-node != goal) or (direction = -1  and to-node != origin)
     [
       set link-counter link-counter + direction
       set current-link item link-counter myroad
       ifelse  ([end1] of current-link = to-node)   [set to-node [end2] of current-link]
                                                    [set to-node [end1] of current-link]
       face to-node
       travel dist - dxnode
       set-emission
     ]
     [ set speed 0
       park
     ]
    ]
end



to park
  let hours item 1 table:get pm10-back (ticks + 1)
  let minutes item 4 table:get pm10-back (ticks + 1)
  let is-weekend? item 6 table:get pm10-back (ticks + 1)

  set parked true
  set tyre-wear  0
  set brake-wear 0
  set surface-wear 0
  set total-emission 0

  ifelse to-node = goal or current = goal
    [ set time-at-work time-at-work - 1
      if (time-at-work <= 0) [to-home-setup ]
     ]
    [ if (hours = leave-home-hour and minutes = leave-home-mins) and is-weekend? = false
         [to-work-setup set time-at-work 540 + random 61]  ;; cars will go to work after 7am
    ]
end


to set-emission
  ;; Tyre wear
  let velocity-tyre 0
  let EF1# 0
  let random_no# random 2
  ifelse speed < 2 [set velocity-tyre 1.39][set velocity-tyre (-.00974 * speed) + 1.78]
  ifelse random_no# = 0 [set EF1# (0.0107 - random-float .004)][set EF1# (0.0107 + random-float .006)]
  set tyre-wear (emission-factor * EF1# * .6 * velocity-tyre) * 333

  ;; Brake wear
  let velocity-brake 0
  let EF2# 0
  let random_no1# random 2
  ifelse speed < 2 [set velocity-brake 1.67][set velocity-brake (-.0270 * speed) + 2.75]
  ifelse random_no1# = 0 [set EF2# (0.0067 - random-float .004)][set EF2# (0.0067 + random-float .006)]
  set brake-wear (emission-factor * EF2# * .6 * velocity-brake) * 333

  ;;  Surface wear
  set surface-wear (emission-factor * .015 * .5) * 333

  ;; Total Emission
  let dilution# (0.5 + random-float .50) ;; wind speed, turbulance, traffic intensity
  set total-emission (tyre-wear + brake-wear + surface-wear) * dilution#
end


to speed-up
  let max-speed 3 + random-float 2
  let min-speed .5
  ask cars [
    set speed min-speed + random-float (max-speed - min-speed)
    let car-ahead one-of (cars-on patch-ahead 1) with [heading = [heading] of myself]
    ifelse car-ahead != nobody and not [parked] of car-ahead
      [ slow-down car-ahead] [set speed speed]
  ]
end


to slow-down [car-ahead ]
  ;; slow down so you are driving more slowly than the car ahead of you
  let deceleration 0 + random-float 3
  set speed [ speed ] of car-ahead - deceleration

end




to set-signal-colours
  let hours item 1 table:get pm10-back (ticks + 1)

  ask nodes with [intersection? = true] [
   ifelse hours >= 2 and hours < 6
    [ set auto? 10 set color green set green-light? true ]
    [ set auto? auto? - 1
      if auto? >= 5 [set color green set green-light? true]
      if auto? <  5 [set color red set green-light? false]
      if auto? <= 0 [set auto? 5 + random 6]]
  ]
end


to meet-traffic-lights
  ask cars [
  if any? nodes in-radius 2 with [green-light? = false][ set speed 0 ]
  if any? other nodes in-radius 1 with [green-light? = true]
    [set speed (speed + (.5 + random-float 1)) ]
  ]
end


to add-cars
  let CBD_Entrance []
  let input_location (map patch [14 58 131 149 140 102 63 38 18 2 154] [181 184 164 99 46 17 34 40 86 103 191])
  foreach input_location [ x ->
    ask x [
      let val [who] of min-n-of 2 nodes [distance myself]
      let val-link link (item 0 val) (item 1 val)
      if val-link != nobody [set CBD_Entrance lput val-link CBD_Entrance]
      ]]

  create-cars round (item ticks v_sajik * car_ratio / 60) [
   car-info
   let l item 0 CBD_Entrance
   ifelse l = item 0 CBD_Entrance or l = item 1 CBD_Entrance or
          l = item 4 CBD_Entrance or l = item 5 CBD_Entrance or l = item 6 CBD_Entrance
      [set-next-car-link l [end2] of l] ;; ask the vehicles to head south
      [set-next-car-link l [end1] of l] ;; ask the vehicles to head north
  ]

  create-cars round (item ticks v_jahamoon * car_ratio / 60) [
   car-info
   let l item 1 CBD_Entrance
   ifelse l = item 0 CBD_Entrance or l = item 1 CBD_Entrance or
          l = item 4 CBD_Entrance or l = item 5 CBD_Entrance or l = item 6 CBD_Entrance
      [set-next-car-link l [end2] of l] ;; ask the vehicles to head south
      [set-next-car-link l [end1] of l] ;; ask the vehicles to head north
  ]

  create-cars round (item ticks v_daesagwan * car_ratio / 60) [
   car-info
   let l item 2 CBD_Entrance
   ifelse l = item 0 CBD_Entrance or l = item 1 CBD_Entrance or
          l = item 4 CBD_Entrance or l = item 5 CBD_Entrance or l = item 6 CBD_Entrance
      [set-next-car-link l [end2] of l] ;; ask the vehicles to head south
      [set-next-car-link l [end1] of l] ;; ask the vehicles to head north
  ]

  create-cars round (item ticks v_daehak * car_ratio / 60) [
   car-info
   let l item 3 CBD_Entrance
   ifelse l = item 0 CBD_Entrance or l = item 1 CBD_Entrance or
          l = item 4 CBD_Entrance or l = item 5 CBD_Entrance or l = item 6 CBD_Entrance
      [set-next-car-link l [end2] of l] ;; ask the vehicles to head south
      [set-next-car-link l [end1] of l] ;; ask the vehicles to head north
  ]

  create-cars round (item ticks v_jongno * car_ratio / 60) [
   car-info
   let l item 4 CBD_Entrance
   ifelse l = item 0 CBD_Entrance or l = item 1 CBD_Entrance or
          l = item 4 CBD_Entrance or l = item 5 CBD_Entrance or l = item 6 CBD_Entrance
      [set-next-car-link l [end2] of l] ;; ask the vehicles to head south
      [set-next-car-link l [end1] of l] ;; ask the vehicles to head north
  ]


  create-cars round (item ticks v_dongho * car_ratio / 60) [
   car-info
   let l item 5 CBD_Entrance
   ifelse l = item 0 CBD_Entrance or l = item 1 CBD_Entrance or
          l = item 4 CBD_Entrance or l = item 5 CBD_Entrance or l = item 6 CBD_Entrance
      [set-next-car-link l [end2] of l] ;; ask the vehicles to head south
      [set-next-car-link l [end1] of l] ;; ask the vehicles to head north
  ]

  create-cars round (item ticks v_ns2ho * car_ratio / 60) [
   car-info
   let l item 6 CBD_Entrance
   ifelse l = item 0 CBD_Entrance or l = item 1 CBD_Entrance or
          l = item 4 CBD_Entrance or l = item 5 CBD_Entrance or l = item 6 CBD_Entrance
      [set-next-car-link l [end2] of l] ;; ask the vehicles to head south
      [set-next-car-link l [end1] of l] ;; ask the vehicles to head north
  ]

  create-cars round (item ticks v_soparo * car_ratio / 60) [
   car-info
   let l item 7 CBD_Entrance
   ifelse l = item 0 CBD_Entrance or l = item 1 CBD_Entrance or
          l = item 4 CBD_Entrance or l = item 5 CBD_Entrance or l = item 6 CBD_Entrance
      [set-next-car-link l [end2] of l] ;; ask the vehicles to head south
      [set-next-car-link l [end1] of l] ;; ask the vehicles to head north
  ]


  create-cars round (item ticks v_saemunan * car_ratio / 60) [
   car-info
   let l item 8 CBD_Entrance
   ifelse l = item 0 CBD_Entrance or l = item 1 CBD_Entrance or
          l = item 4 CBD_Entrance or l = item 5 CBD_Entrance or l = item 6 CBD_Entrance
      [set-next-car-link l [end2] of l] ;; ask the vehicles to head south
      [set-next-car-link l [end1] of l] ;; ask the vehicles to head north
  ]

  create-cars round (item ticks v_ssm * car_ratio / 60) [
   car-info
   let l item 9 CBD_Entrance
   ifelse l = item 0 CBD_Entrance or l = item 1 CBD_Entrance or
          l = item 4 CBD_Entrance or l = item 5 CBD_Entrance or l = item 6 CBD_Entrance
      [set-next-car-link l [end2] of l] ;; ask the vehicles to head south
      [set-next-car-link l [end1] of l] ;; ask the vehicles to head north
  ]
end

to car-info
   set random-car true
   set parked false
   set size 2
   set speed random-float 2
   set unwell_history false
   let f_type# random 3
   if f_type# = 0 [set fueltype "Gasoline"]
   if f_type# = 1 [set fueltype "Diesel"]
   if f_type# = 2 [set fueltype "LPG"]
end


to drive-out-of-cbd
  let is-weekend? item 6 table:get pm10-road (ticks + 1)
  let what-time?  item 1 table:get pm10-road (ticks + 1)


  ask cars with [random-car] [ if any? cars-on nodes-here with [endpoint?][die]]
  ask cars with [not random-car] [ if is-weekend? and what-time? >= (8 + random 2) and what-time? < 22 and any? cars-on nodes-here with [endpoint?][set speed 0]
    if is-weekend? and what-time? < 8 or what-time? >= 22 and any? cars-on nodes-here with [endpoint?][move-to origin]
  ]
end


to kill-cars
  let night item 1 table:get pm10-back (ticks + 1)
  ;let is-weekend? item 6 table:get pm10-road (ticks + 1)

  if (night >= 8 and night < 23 )
   [ ask n-of (int(.05 * car_ratio * count cars with [random-car = true])) cars with [random-car = true] [die]]

  if (night >= 23 and night < 24 or night < 4)
   [ ask n-of (int(.02 * car_ratio * count cars with [random-car = true])) cars with [random-car = true] [die]]
end


to move-drivers
    ask drivers with [my_car != nobody][
    if ([parked] of my_car = true) and ([current] of my_car = [goal] of my_car) [ move-to [destination] of my_car ]
    if ([parked] of my_car = true) and ([current] of my_car = [origin] of my_car) [ move-to [origin] of my_car ]
  ]

end



to add-employees
  let hours item 1 table:get pm10-back (ticks + 1)
  let mins item 4 table:get pm10-back (ticks + 1)
  let is-weekend? item 6 table:get pm10-road (ticks + 1)

  ask employees [
    if (hours = leave-home-hour and mins = leave-home-mins) and is-weekend? = false [
      move-to origin
      set Heuristic distance goal
      set current patch-here
      set direction 1
      set arrive-tick ticks
      set unwell_history false
    ]
  ]
end


to move-employees
  ask employees with [goal != nobody][
    set current patch-here
    set Heuristic distance goal
    ifelse (patch-here != goal and direction = 1) [
      if (awareness = "no") [walk-to-work]
      if (awareness = "yes") [walk-with-awareness]
    ]
    [
      work-hard
      if (time-at-work <= 0) [ set direction -1 head-home ]
      ]
  ]
end


to walk-with-awareness
  set color 103
  set arrived? false
  set hidden? false
  set time-at-work 540 + random 61

  let choice1 neighbors with [pm10 < 100]
  let nearest1 min-one-of choice1 [distance [goal] of myself ]
  let choice2 min-n-of 3 neighbors [pm10]
  let nearest2 min-one-of choice2 [distance [goal] of myself ]

  ifelse nearest1 != nobody [move-to nearest1][move-to nearest2]
  face [goal] of self
  fd (0.7 + random-float .3)
 if [Heuristic] of self <= 1 [move-to goal]
end


to walk-to-work
  set color 103
  set arrived? false
  set hidden? false
  ;let choices neighbors with [pavement]
  let nearest min-one-of neighbors [distance [goal] of myself ]
  set time-at-work 540 + random 61
  face nearest
  fd (0.7 + random-float .3)
end


to head-home
  set Heuristic distance origin
  let hours item 1 table:get pm10-back (ticks + 1)
  let nearest min-one-of neighbors [distance [origin] of myself ]
  set color brown + 2
  set arrived? false
  set hidden? false
  ifelse current = myhome [set time-at-work 0 fd 0 set arrive-tick 0][ face nearest fd (.6 + random-float .4) ]
  if distance origin <= 1 [ move-to myhome ]
end



to work-hard
  let hours item 1 table:get pm10-back (ticks + 1)
  let minutes item 4 table:get pm10-back (ticks + 1)
  set arrived? true
  if (ticks - arrive-tick) > 80 [set hidden? true]
  set direction 0
  set color grey
  fd 0
  ifelse time-at-work < 0 [set direction -1] [set time-at-work time-at-work - 1 ]
end


;to building-update
; let b_list [self] of buildings
; foreach b_list [ one-building ->
;   ask one-building [ set count-employees count employees with [myoffice = myself]]
;  ]
;end

;;----------------Set exposure & Impact--------------;;
to pollute
;Small Vehicles
  ask cars with [not parked and speed > 0][
    let polluting one-of [link-neighbors] of to-node
    let mycar self
    let pm10# (item 2 table:get pm10-back (ticks + 1)) + random-float (item 3 table:get pm10-back (ticks + 1))

    ask patches in-cone 2.5 90 [
      set pcolor grey + 2
      set pm10 (pm10# * .73) + [total-emission] of mycar  ;; Removing 23% the PM10 from vehicle contribution
                                                          ;; According to Weinbruch et al (2014)
    ]
  ]

  ask patches with [pcolor != (grey + 2) and is-research-area? = true][
    set pm10 (item 2 table:get pm10-back (ticks + 1)) + random-float (item 3 table:get pm10-back (ticks + 1))
  ]

  ;; cars
  ask cars with [owner != 0][
    ask origin [set pm10_indoor ([pm10] of patch-here) * (.2 + random-float .5 ) ]
  ]

  ;; set buildings
  ask buildings [
   ask patch-here [ set pm10_indoor pm10 * (.2 + random-float .5 )  ]
  ]

  ;; in the left bottom corner
  ask patch max-pxcor max-pycor
    [ let night item 1 table:get pm10-others (ticks + 1)
      ifelse night > 23 or night < 6
      [ set pm10 ((item 2 table:get pm10-others (ticks + 1)) +
        random-float (item 3 table:get pm10-others (ticks + 1))) * .25  ]
      [ set pm10 (item 2 table:get pm10-others (ticks + 1)) +
        random-float (item 3 table:get pm10-others (ticks + 1)) * (1 - random-float .75 )]
    ]

  ;; for resident vehicles going outside
  ask patches with [is-endpoint?]
    [ let night item 1 table:get pm10-others (ticks + 1)
      ifelse night > 23 or night < 6
      [ set pm10 ((item 2 table:get pm10-others (ticks + 1)) +
        random-float (item 3 table:get pm10-others (ticks + 1))) * (.25 + random-float .5)  ]
      [ set pm10 (item 2 table:get pm10-others (ticks + 1)) +
        random-float (item 3 table:get pm10-others (ticks + 1)) ]
    ]
end


to fadeout
  ask patches with [pcolor = (grey + 2)][      ;; We set the dilution function to fade out
    ifelse countdown <= 0                      ;; after 3 ticks or less
      [ set pcolor white
        set countdown random 3 ]
      [ set countdown countdown - 1 ]
  ]
end


;;--------------- Health Loss & Recover ------------------;;
to health-loss
  ask employees [
    if ([pm10] of patch-here >= 100 and arrived? = false)
      [set health health - ((random-float health_loss) * (310 - health))]
    if ([pm10_indoor] of patch-here != nobody and [pm10_indoor] of patch-here >= 100 and arrived? = true)
      [set health health - ((random-float health_loss) * (310 - health))]
    if health < 100 [set unwell_history true ]
    if health < 0 [set health 0]
  ]


  ask cars with [owner != 0][
    if not parked and ([pm10] of patch-here * 0.7) >= 100 [set health health - ((random-float health_loss) * (310 - health)) ]
    if parked and [pm10_indoor] of destination >= 100 [set health health - ((random-float health_loss) * (310 - health)) ]
    if health < 100 [set unwell_history true ]
    if health < 0 [set health 0]
  ]

  ask drivers with [my_car != nobody][
    if [parked] of my_car = false [ set health [health] of my_car ]]
end


to health-recovery
  ask employees with [current = myhome or current = goal and health < 250]
     [ if health >= 0 and health < 100 [set health health + (medication + random-float medication) ]]
  ask cars with [owner != 0 and parked and health >= 0 and health < 250]
     [ if health >= 0 and health < 100 [set health health + (medication + random-float medication) ]]
  ask drivers with [my_car != nobody][ set health [health] of my_car]

end


;;-------

to validation-plot
  set-current-plot "Validation"
  set-current-plot-pen "Jongno" plot([pm10] of patch 134 98)
  set-current-plot-pen "Jung" plot([pm10] of patch 38 68)
  set-current-plot-pen "Jongno Kerb" plot([pm10] of patch 105 95) ;; Jongno kerb
  set-current-plot-pen "Seoul Stn" plot([pm10] of patch 40 42)

end


to age-plot
 set-current-plot "Health by Age"
 set-current-plot-pen "Drivers" plot(count(drivers with [health < 100]) / count drivers * 100)
 set-current-plot-pen "Walkers" plot(count(employees with [health < 100]) / count employees * 100)

end

;;-----------
to store-raster
  let patches_out nobody
  ask one-of patches [
    set patches_out gis:patch-dataset pm10
  ]

  gis:store-dataset patches_out (word "Spatial_Output/patch_out_check" "_" but-first (word (10000 + ticks)) ".asc")
end
@#$#@#$#@
GRAPHICS-WINDOW
632
40
1105
625
-1
-1
3.0
1
11
1
1
1
0
1
1
1
0
154
0
191
1
1
1
Minutes
2000.0

BUTTON
18
33
85
66
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
93
96
166
129
Shape
draw-4daemoon
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
171
95
232
128
Map-del
cd
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
96
87
129
Localmap
draw-map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
20
218
91
263
total.cars
count cars
17
1
11

TEXTBOX
838
10
1033
48
Seoul CBD
18
0.0
1

BUTTON
94
33
157
66
NIL
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

TEXTBOX
19
10
169
28
* Working
11
0.0
1

TEXTBOX
17
73
167
91
* Aesthetics
11
0.0
1

BUTTON
165
34
228
67
step
go
NIL
1
T
OBSERVER
NIL
T
NIL
NIL
1

TEXTBOX
17
138
167
156
* Time Scale
11
0.0
1

MONITOR
20
160
119
205
Date
item 0 table:get pm10-road ticks
1
1
11

MONITOR
129
160
186
205
Hours
item 1 table:get pm10-road ticks
17
1
11

MONITOR
197
160
261
205
Minutes
item 4 table:get pm10-road ticks
17
1
11

MONITOR
340
158
443
203
People-at-Home
count employees-on patch max-pxcor max-pycor
17
1
11

MONITOR
265
219
320
264
pm10
precision mean [pm10] of patches with [is-research-area? = true] 2
17
1
11

PLOT
12
502
172
622
Validation
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Jongno" 1.0 0 -16777216 true "" ""
"Jung" 1.0 0 -7500403 true "" ""
"Jongno Kerb" 1.0 0 -2674135 true "" ""
"Seoul Stn" 1.0 0 -955883 true "" ""

MONITOR
267
159
334
204
Weekdays
item 5 table:get pm10-road ticks
17
1
11

PLOT
192
504
352
624
Health by Age
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Drivers" 1.0 0 -7500403 true "" ""
"Walkers" 1.0 0 -2674135 true "" ""

SLIDER
17
365
142
398
health_loss
health_loss
0.005
0.1
0.01
0.005
1
NIL
HORIZONTAL

TEXTBOX
348
347
498
365
* Car Related Parameters
12
0.0
1

INPUTBOX
450
158
545
218
no-of-employees
1932.0
1
0
Number

SLIDER
347
366
469
399
emission-factor
emission-factor
1
10
5.0
1
1
NIL
HORIZONTAL

PLOT
369
505
529
625
Temporary Cars
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot count cars with [random-car = true]"

MONITOR
94
219
162
264
Temp.Cars
count cars with [random-car = true]
17
1
11

MONITOR
20
277
87
322
Unwell%
Walkers_p
17
1
11

SLIDER
153
364
266
397
medication
medication
0
30
10.0
1
1
NIL
HORIZONTAL

CHOOSER
279
34
371
79
awareness
awareness
"no" "yes"
0

MONITOR
182
277
259
322
NearRd.Sub
(count employees with [work-near-roads? = true])
17
1
11

MONITOR
263
277
338
322
NearRd.Car
(count cars with [work-near-roads? = true])
17
1
11

SLIDER
474
366
593
399
car_ratio
car_ratio
00
.1
0.05
.005
1
NIL
HORIZONTAL

MONITOR
169
221
250
266
Local.Cars
count cars with [random-car = false]
17
1
11

MONITOR
92
276
165
321
Unwell.Car
Drivers_p
17
1
11

CHOOSER
383
34
477
79
export-raster
export-raster
"no" "yes"
0

TEXTBOX
475
403
569
436
BAU: 0.05\n50% ban: 0.025\n90% ban: 0.005
10
0.0
1

@#$#@#$#@
## WHAT IS IT?
The purpose of this model is to understand commuter’s exposure to non-exhaust PM<sub>10</sub> emissions, and to make a preliminary estimate of their health effects. This model tests whether reducing traffic can alleviate the pollution levels and whether taking a polluted but quicker path or less polluted but longer path makes a difference to pedestrians' exposure levels.

## HOW IT WORKS
* Agent behaviour
    - As the simulation executes, the pedestrians will start moving from their home to work. You will see 'people at home' are decreasing rapidly, which means they are somewhere heading to the office or have started working. Pedestrians will appear on one of the 26 subway entrances in the study area. Pedestrians who have arrived at their offices will disappear after 80 ticks. This to avoid any visual clutter on the screen. Do not worry, they will appear after work. If you want to check the remainder of the agents work hours, simply inspect the attributes and check 'time-at-work'.
    - The resident vehicles that appeared right after the setup, will start their journey to their workplaces as per the A* algorithm. The vehicles will arrive and stop on the node that is closest to their workplace. They will return home after work. 
    - Non-residents have a free trip in the city centre and drive out randomly. The input of the vehicles is controlled according to the traffic count data provided from Seoul Traffic Monitoring Service.

* Exposure
    - PM<sub>10</sub> levels are amplified in near road areas when a vehicle passes by.
    - Pedestrians who are within 1 radius (<30 metres) from the vehicles will be exposed to high PM<sub>10</sub>
    - Agents who are exposed to 100µg/m3 or over will lose their health


## HOW TO USE IT
Once the Netlogo interface is loaded, you will see three buttons on the top row setup, go, step. 
Please click on the setup to load the vehicles. You can untick the "view updates" tick box right next to the speed slider. Once you see the map and vehicles ready, it is time to click go. You can also click step instead of go if you fancy to look into each step. 

Once the simulation is running, you would see that the date, hours and minutes are changing.

You will see to screens in the middle displayed as Unwell% and Unwell.Car, each of which is accounts for pedestrians and resident vehicle drivers. This will change over time.

The **health loss** slide will change the level of health degrading. Since an individual's initial health begins with 300, I would say the maximum to be 0.2. But feel free to toggle the slides. **Medication** is the temporary recovery level when an individual arrives indoors. This assumes that people take medicine when they feel unwell. **Emission factor** is a parameter that can control the level of PM<sub>10</sub>. Parameter 1 refers to no effect while 20 is almost 3 times higher than the ambient level. This has been fully tested through the sensitivity test. **car-ratio** controls the level of incoming vehicles (non-resident) to the CBD. 


## THINGS TO NOTICE
Note that these vehicles will move freely during the weekend but to put them back to the A* algorithmic route, we had to coerce the vehicles. As a result, you can see vehicles flying back home.


## THINGS TO TRY
As mentioned earlier, feel free to toggle any sliders. Note that **car-ratio** is the only parameter that gives an immediate difference on the screen, while the others require some time to before the change takes an effect.

## EXTENDING THE MODEL
The model extended the Seoul Air Pollution Exposure model published in JASSS (http://jasss.soc.surrey.ac.uk/22/1/12.html). The NetLogo model is also released in ComSES model library (https://www.comses.net/codebases/cb6c2243-fb44-4543-a372-6fee5f034c40/releases/1.1.0/). The published model only requested people to move between origin points and destination points (2 point movement) due to the lack of travel information. Out new model narrowed down the spatial extent but added movement patterns and elaborated temporal scales to a minute basis.

Another model that inspired me was the Venice model (https://www.gisagents.org/2009/02/agent-based-models-for-venice.html). 


## NETLOGO FEATURES
nw and gis extension


## RELATED MODELS
Seoul Air Pollution model https://www.comses.net/codebases/cb6c2243-fb44-4543-a372-6fee5f034c40/releases/1.1.0/


## CREDITS AND REFERENCES

Thanks to Andrew Crooks for achiving the Venice model. The model was deprecated for some reason, but thanks to you I managed to learn the codes and developed it for this study.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car side
false
0
Polygon -7500403 true true 19 147 11 125 16 105 63 105 99 79 155 79 180 105 243 111 266 129 253 149
Circle -16777216 true false 43 123 42
Circle -16777216 true false 194 124 42
Polygon -16777216 true false 101 87 73 108 171 108 151 87
Line -8630108 false 121 82 120 108
Polygon -1 true false 242 121 248 128 266 129 247 115
Rectangle -16777216 true false 12 131 28 143

chess rook
false
0
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 90 255 105 105 195 105 210 255
Polygon -16777216 false false 90 255 105 105 195 105 210 255
Rectangle -7500403 true true 75 90 120 60
Rectangle -7500403 true true 75 84 225 105
Rectangle -7500403 true true 135 90 165 60
Rectangle -7500403 true true 180 90 225 60
Polygon -16777216 false false 90 105 75 105 75 60 120 60 120 84 135 84 135 60 165 60 165 84 179 84 180 60 225 60 225 105

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="air quality" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="127741"/>
    <metric>mean-pm10</metric>
    <metric>back_pm10_sample</metric>
    <metric>JongnoKerb_p</metric>
    <metric>Sejong_p</metric>
    <metric>Pirum_p</metric>
    <metric>Yulgok_p</metric>
    <enumeratedValueSet variable="emission-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="medication">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="health_loss">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="awareness">
      <value value="&quot;no&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car_ratio">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-of-employees">
      <value value="1932"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
