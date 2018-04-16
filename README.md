# console-visual-METAR
Download, decode and visualize METAR weather on a colorful Map on Linux console.
METAR sentence parser originally taken from the package tclmetar-0.1 from the Tcl/Tk web site,
 although it has been changed from ftp to http and added ANSI support, and modified slightly.
 Link to original: http://wiki.tcl.tk/19635

Preconditions to run this software:
0) TCL support
   This software has been written in TCL, so You'll need Tclsh installed

1) ANSI support on Your console
   All drawing happens using ANSI escape sequences. Almost all Linux/Unix terminals support now ANSI,
   but if You want to test Your own terminal please type this at the command line:
   echo -e "\e[1;31mThis should be red. \e[1;32mAnd this should be green.\e[0m"
   If You can see these 2 sentences in appropriate color then You have ANSI support.

2) At least 100x45 characters terminal size. Smaller sizes also work but look ugly.
   A beautiful view is at 200x60 characters.

3) COLUMNS and LINES environmental variables EXPORTED !
   Put in "export COLUMNS" and "export LINES" in Your Shell's RC file  (like: .bashrc)


Usage:
* Put in Your Home location in the first data row of the Stations.txt file (right below the header)
  Put in "HOME;<Your city name>;<Latitute>;<Longitude>;<Sea level>;0km;0"
* Underneath this in the following rows put in the list of stations You want to monitor.
  At the moment there are a bunch of central European stations.
* Start the software
* <this will be deleted if help window will be available inside the program>
  Use following commands inside the program:
  GO   <north/south/east/west/up/down/left/right>  -- navigate on the map
  GOTO   <stations's ICAO code>   -- center the station on the map and view METAR data (raw and decoded)
  ZOOM   <in/out>   -- change map's zoom level
  RETRIEVE   <mask>   -- download data from noaa web site into file for all stations matching <mask>
  RELOAD   -- Reload METAR data from the data files into memory
  REFRESH   -- Redraw the whole screen
  EXIT , QUIT   -- Exit the program
  LABEL   -- Change what short information is displayed for each station's label
    ICAO   -- the ICAO code of the station (default)
    TEMP   -- Temperature at the station
    WIND   -- Wind speed at the station
    PRES   -- Air pressure at the station
    WTHR   -- Short weather code at the station
* Possibility to expand map:
  Take Google Maps or WanderReitKarte , and draw a line along a border or river and save it as gpx file.
  Putting it into the _gpx folder with the name rivr-_name_.gpx or bord-_name_.gpx will be automatically loaded and used.
  For areas do the same drawing a polygon around the area and save it using above method.
  * Weak point for drawing areas: see BUGS section below!


BUGS and Still to do:
* All Station distances and directions are calculated from Szombathely (fixed)
  Need to change to auto-calculate from the HOME location.
* Need "HELP" command and a help screen showing the Commands and Legend.
* Area drawing algorhythm is lame. Horizontally concave areas are OK (like the letter C),
  but if area is vertically concave (like the letter U) then the whole area is filled.
  Need a contributor's help to solve the issue.
  As a temporary solution the area must be split into two halves to avoid vertical concaveness.
* If there is data file coming from NOAA but the report inside is old, the software still considers the data as fresh.
  Need to check the date string as well and set the data to "old" (red label on the map).
* Nice-to-have feature would be a bright white scale in the bottom right corner.
