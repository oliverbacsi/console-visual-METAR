# console-visual-METAR
Download, decode and visualize METAR weather on a colorful Map on Linux console.

![Screenshot](https://github.com/oliverbacsi/console-visual-METAR/blob/master/Screenshot.png)

METAR sentence parser originally taken from the package tclmetar-0.1 from the Tcl/Tk web site,<BR>
 although it has been changed from ftp to http and added ANSI support and modified slightly.<BR>
 Link to original: http://wiki.tcl.tk/19635


## Preconditions to run this software:

0. TCL support<BR>
   This software has been written in TCL, so You'll need Tclsh installed.

1. ANSI support on Your console<BR>
   All drawing happens using ANSI escape sequences. Almost all Linux/Unix terminals support now ANSI,<BR>
   but if You want to test Your own terminal please type this at the command line:<BR>
   echo -e "\e[1;31mThis should be red. \e[1;32mAnd this should be green.\e[0m"<BR>
   If You can see these 2 sentences in appropriate color then You have ANSI support.

2. At least 100x45 characters terminal size. Smaller sizes also work but look ugly.<BR>
   A beautiful view is at 200x60 characters.

3. COLUMNS and LINES environmental variables EXPORTED !<BR>
   Put in "export COLUMNS" and "export LINES" in Your Shell's RC file  (like: .bashrc)


## Usage:

* Put in Your Home location in the first data row of the Stations.txt file (right below the header)<BR>
  Put in "HOME;_Your city name_;_Latitute_;_Longitude_;_Sea level_;0km;0"

* Underneath this in the following rows put in the list of stations You want to monitor.<BR>
  At the moment there are a bunch of central European stations.

* Start the software

* Possibility to expand map:<BR>
  Take Google Maps or WanderReitKarte , and draw a line along a border or river and save it as gpx file.<BR>
  Putting it into the _gpx folder with the name rivr-_name_.gpx or bord-_name_.gpx will be automatically loaded and used.<BR>
  For areas do the same drawing a polygon around the area and save it using above method.<BR>
  * Weak point for drawing areas: see BUGS section below!<BR>


## BUGS and Still to do:

- [ ] All Station distances and directions are calculated from Szombathely (fixed)<BR>
  Need to change to auto-calculate from the HOME location.

- [X] Need a HELP command that displays command list and legend.

- [ ] Area drawing algorhythm is lame. Horizontally concave areas are OK (like the letter C),<BR>
  but if area is vertically concave (like the letter U) then the whole area is filled.<BR>
  Need a contributor's help to solve the issue.<BR>
  As a temporary solution the area must be split into two halves to avoid vertical concaveness.<BR>

- [ ] If there is data file coming from NOAA but the report inside is old, the software still considers the data as fresh.<BR>
  Need to check the date string as well and set the data to "old" (red label on the map).<BR>

- [ ] Nice-to-have feature would be a bright white scale in the bottom right corner.<BR>
