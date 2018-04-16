#!/usr/bin/tclsh

#lappend auto_path ../../_alien/tclmetar-0.1/
#package require tclmetar

########## INIT PART ##########

package require http
source tclmetar.tcl
array set Stations {_ {}} ; global Stations
array set Map {bord,_ {} city,_ {} hill,_ {} lake,_ {} mntn,_ {} rivr,_ {} snow,_ {} limit,L 100 limit,R -100 limit,T 0 limit,B 90 view,left 14.25 view,top 48.25 view,charperdeg 24.0} ; global Map
array set Curr {Station HOME LabelMode ICAO} ; global Curr
array set AnsiOf {rivr "\033\[1;34m" bord "\033\[1;35m" grass "\033\[0;32m" hill "\033\[0;33m" mntn "\033\[1;30m" snow "\033\[0;37m" city "\033\[1;33;43m" lake "\033\[1;36;44m"} ; global AnsiOf
global env


########## PROC PART ##########

proc retrieve_metar_data_to_file {_mask} {
global Stations

  foreach _sta $Stations(_) {
    if {![string match -nocase $_mask $_sta]} continue
    set fout [open _data/$_sta.TXT w]
    catch {set TOKEN [::http::geturl "http://tgftp.nws.noaa.gov/data/observations/metar/stations/$_sta.TXT" -channel $fout -blocksize 1000000 -timeout 60000]}
    close $fout
    ::http::cleanup $TOKEN
  }
  reload_metar_data
  puts -nonewline "\033\[1;32m*** READY.\033\[0m" ; flush stdout
}


proc reload_station_data {} {
global Stations

  set fin [open Stations.txt r] ; gets $fin
  while {![eof $fin]} {
    set sList [split [gets $fin] ";"]
    if {[llength $sList] < 4} continue
    set ICAO [lindex $sList 0]
    lappend Stations(_) $ICAO
    set Stations($ICAO,Dsc) [lindex $sList 1]
    set Stations($ICAO,Lat) [string range [lindex $sList 2] 0 10]
    set Stations($ICAO,Lon) [string range [lindex $sList 3] 0 10]
    set Stations($ICAO,Alt) [lindex $sList 4]
    set Stations($ICAO,Dst) [string range [lindex $sList 5] 0 10]
    set Stations($ICAO,Dir) [string range [lindex $sList 6] 0 10]
  }
  close $fin
}


proc reload_metar_data {} {
global Stations

  foreach sta $Stations(_) {
    if {[catch {set fin [open "_data/$sta.TXT" r]}]} {
      set Stations($sta,metar,ansi_raw) "\033\[1;31m!\033\[0;31m$sta\033\[1;31m!\033\[0m No Data!"
      set Stations($sta,metar,ansi_eur) "\033\[1;31m!\033\[0;31m$sta\033\[1;31m!\033\[0m No Data!"
      continue
    }
    gets $fin
#    set Stations($sta,Decoded) [::tclmetar::parse [gets $fin] $sta]
    array set _tempArray [::tclmetar::parse [gets $fin] $sta]
    close $fin
    foreach idx [array names _tempArray] {
      set Stations($sta,metar,$idx) "$_tempArray($idx)"
    }
  }
}


proc getgrass {} {
  return [string index ".ˇ:˘°˛`,˙'˝¸;" [expr int(169.0*rand())%13]]
}
proc getbord {} {
  return [string index "@QOD0" [expr int(25.0*rand())%5]]
}
proc getrivr {} {
  return [string index "zZ~Ss$" [expr int(36.0*rand())%6]]
}
proc getlake {} {
  return [string index "~-~÷:;" [expr int(36.0*rand())%6]]
}
proc getcity {} {
  return [string index "#HWM" [expr int(64.0*rand())%4]]
}
proc gethill {} {
  return [string index "mnaoebdgq" [expr int(81.0*rand())%9]]
}
proc getmntn {} {
  return [string index "MANYF" [expr int(25.0*rand())%5]]
}
proc getsnow {} {
  return [string index "A^Á˘VM" [expr int(36.0*rand())%6]]
}


proc load_map_files {} {
global Map

  cd _gpx
  foreach fn [glob -nocomplain *.gpx] {
    set cat [string range $fn 0 3]
    set dsc [string range $fn 5 end-4]
    set limit_t 0 ; set limit_b 90
    set limit_l 100 ; set limit_r -100
    set fin [open $fn r]
    while {![eof $fin]} {
      set sor [gets $fin]
      if { [regexp {<rtept.lat=.([0-9\.]*)..lon=.([0-9\.]*).>} $sor m lat lon] } {
        lappend Map($cat,$dsc,coordlist) $lat $lon
        if {$lat > $limit_t} {set limit_t $lat}
        if {$lat < $limit_b} {set limit_b $lat}
        if {$lon < $limit_l} {set limit_l $lon}
        if {$lon > $limit_r} {set limit_r $lon}
      }
    }
    close $fin
    lappend Map($cat,_) $dsc
    set Map($cat,$dsc,limit_t) $limit_t ; set Map($cat,$dsc,limit_r) $limit_r
    set Map($cat,$dsc,limit_b) $limit_b ; set Map($cat,$dsc,limit_l) $limit_l
    if {$limit_l < $Map(limit,L)} {set Map(limit,L) $limit_l}
    if {$limit_r > $Map(limit,R)} {set Map(limit,R) $limit_r}
    if {$limit_b < $Map(limit,B)} {set Map(limit,B) $limit_b}
    if {$limit_t > $Map(limit,T)} {set Map(limit,T) $limit_t}
  }
  cd ..
}


proc redrawscreen {} {
global env Stations Map Curr AnsiOf

# Map default limits:   Lat:46.25-48.25    Lon: 14.5-19.5

# Main frame and grass background
  puts -nonewline "\033\[0m\033\[2J\033\[H"
  for {set i 0} {$i < $env(COLUMNS)} {incr i} {puts -nonewline "#"}
  for {set j 7} {$j < $env(LINES)}   {incr j} {
    puts -nonewline "\033\[0m#                    #$AnsiOf(grass)"
    for {set i 23} {$i < $env(COLUMNS)} {incr i} {puts -nonewline [getgrass]}
    puts -nonewline "\033\[0m#"
  }
  for {set i 0} {$i < $env(COLUMNS)} {incr i} {puts -nonewline "#"}
  for {set j 0} {$j < 2} {incr j} {
    puts -nonewline "\033\[0m#"
    for {set i 2} {$i < $env(COLUMNS)} {incr i} {puts -nonewline " "}
    puts -nonewline "#"
  }
  for {set i 0} {$i < $env(COLUMNS)} {incr i} {puts -nonewline "#"}

# Station details in the details windows
  puts -nonewline "\033\[0m\033\[3A\033\[3C\033\[E\033\[2CMETAR RAW:     $Stations($Curr(Station),metar,ansi_raw)"
  puts -nonewline "\033\[0m\033\[E\033\[2CMETAR DECODED: $Stations($Curr(Station),metar,ansi_eur)"

  puts -nonewline "\033\[3;3H\033\[0mICAO:   \033\[1;30;47m$Curr(Station)\033\[0m"
  set cY 5
  foreach {txt idx col} {
    "Airport Name:" Dsc "\033\[1;37m" \
    "Latitude:"     Lat "\033\[1;33m" \
    "Longitude:"    Lon "\033\[1;33m" \
    "Altitude:"     Alt "\033\[1;32m" \
    "Distance:"     Dst "\033\[1;36m" \
    "Direction:"    Dir "\033\[1;34m"
  } {
    puts -nonewline "\033\[$cY;3H\033\[0m$txt" ; incr cY
    puts -nonewline "\033\[$cY;4H$col$Stations($Curr(Station),$idx)" ; incr cY 2
  }
  puts -nonewline " \033\[0;34m([::tclmetar::get_winddirstr [expr int($Stations($Curr(Station),Dir))]])"

  puts -nonewline "\033\[0m\033\[[expr $env(LINES)-1];1H"


###0 : Adjust map view
  set Map(horzchars) [expr $env(COLUMNS)-23]
  set Map(vertchars) [expr $env(LINES)-7]
  set Map(view,right) [expr $Map(view,left)+$Map(horzchars)/$Map(view,charperdeg)]
  set Map(view,bottom) [expr $Map(view,top)-$Map(vertchars)/$Map(view,charperdeg)]

###1 : Decide what is on the map
  foreach cat {bord rivr hill mntn snow city lake} {
    set Map($cat,_onscreen) {}
    foreach id $Map($cat,_) {
      set HaveOnScreen 0
      foreach {lat lon} $Map($cat,$id,coordlist) {
        if {($lat >= $Map(view,bottom)) && ($lat <= $Map(view,top)) && ($lon >= $Map(view,left)) && ($lon <= $Map(view,right))} {set HaveOnScreen 1}
      }
      if {$HaveOnScreen} {lappend Map($cat,_onscreen) $id}
    }
  }

###2 : Line interpolation: as usual
  foreach cat {bord rivr} {
    foreach id $Map($cat,_onscreen) {
      set Map($cat,$id,screencoords1) {}
      foreach {lat lon} $Map($cat,$id,coordlist) {
        set clat [lat2c $lat]
        set clon [lon2c $lon]
        set citem [list $clat $clon]
        set Map($cat,$id,screencoords1) [interpolate_line $Map($cat,$id,screencoords1) $citem]
      }
      set Map($cat,$id,screencoords) {}
      foreach citem $Map($cat,$id,screencoords1) {
        foreach {clat clon} $citem {}
        if {($clat < $Map(vertchars)) && ($clat >= 0) && ($clon < $Map(horzchars)) && ($clon >= 0)} {
          lappend Map($cat,$id,screencoords) $citem
        }
      }
      unset Map($cat,$id,screencoords1)
    }
  }

###3 : Area interpolation: crop at the edge of the map , include the square edges
  foreach cat {hill mntn snow city lake} {
    foreach id $Map($cat,_onscreen) {
      set Map($cat,$id,screencoords1) {}
      foreach {lat lon} $Map($cat,$id,coordlist) {
        set clat [lat2c $lat]
        set clon [lon2c $lon]
        set citem [list $clat $clon]
        set Map($cat,$id,screencoords1) [interpolate_line $Map($cat,$id,screencoords1) $citem]
      }
      set Map($cat,$id,screencoords) {}
      foreach citem $Map($cat,$id,screencoords1) {
        foreach {clat clon} $citem {}
        if {$clat >= $Map(vertchars)} {set clat [expr $Map(vertchars)-1]}
        if {$clat < 0}                {set clat 0}
        if {$clon >= $Map(horzchars)} {set clon [expr $Map(horzchars)-1]}
        if {$clon < 0}                {set clon 0}
        set citem [list $clat $clon]
        lappend Map($cat,$id,screencoords) $citem
      }
      unset Map($cat,$id,screencoords1)
    }
  }

###4 : Transform the Areas to a series of Lines
  foreach cat {hill mntn snow city lake} {
    foreach id $Map($cat,_onscreen) {
      catch {array unset SC} ; array set SC {MinLat 1000000 MaxLat -1000000}
      foreach citem $Map($cat,$id,screencoords) {
        foreach {clat clon} $citem {}
        if {$clat < $SC(MinLat)} {set SC(MinLat) $clat}
        if {$clat > $SC(MaxLat)} {set SC(MaxLat) $clat}
        if {[info exists SC(MinLonOf,$clat)]} {
          if {$clon < $SC(MinLonOf,$clat)} {set SC(MinLonOf,$clat) $clon}
          if {$clon > $SC(MaxLonOf,$clat)} {set SC(MaxLonOf,$clat) $clon}
        } else {
          set SC(MinLonOf,$clat) $clon
          set SC(MaxLonOf,$clat) $clon
        }
      }
      set Map($cat,$id,screencoords) {}
      for {set clat $SC(MinLat)} {$clat <= $SC(MaxLat)} {incr clat} {
        for {set clon $SC(MinLonOf,$clat)} {$clon <= $SC(MaxLonOf,$clat)} {incr clon} {
          set citem [list $clat $clon]
          lappend Map($cat,$id,screencoords) $citem
        }
      }
    }
  }

###5 : Draw the screen items
  foreach cat {hill mntn snow city lake bord rivr} {
    puts -nonewline "\033\[0m$AnsiOf($cat)"
    foreach id $Map($cat,_onscreen) {
      foreach citem $Map($cat,$id,screencoords) {
        foreach {clat clon} $citem {}
        puts -nonewline "\033\[[expr $clat+2]\;[expr $clon+23]H[get$cat]"
      }
    }
  }

###6 : Draw the Stations
  foreach sta $Stations(_) {
    if {($Stations($sta,Lat) < $Map(view,bottom)) || ($Stations($sta,Lat) > $Map(view,top)) || ($Stations($sta,Lon) > $Map(view,right)) || ($Stations($sta,Lon) < $Map(view,left))} continue
    set clat [lat2c $Stations($sta,Lat)] ; set clon [lon2c $Stations($sta,Lon)]
    if {"$sta" eq "HOME"} {
      set _col "\033\[1;37;46m"
    } elseif {(![file exists "_data/$sta.TXT"]) || ([file size "_data/$sta.TXT"] < 20) || ([string length $Stations($sta,metar,ansi_raw)] == 23)} {
      set _col "\033\[0;30;41m"
    } elseif {[expr [clock seconds]-[file mtime "_data/$sta.TXT"]] < 3600} {
      set _col "\033\[0;30;42m"
    } else {
      set _col "\033\[0;30;47m"
    }
    switch -nocase -- $Curr(LabelMode) {
      ICAO {set _txt $sta}
      TEMP { if {[info exists Stations($sta,metar,temperature)]} {set _txt $Stations($sta,metar,temperature)} else {set _txt "??"} }
      WIND { if {[info exists Stations($sta,metar,windspeed)]}   {set _txt $Stations($sta,metar,windspeed)}   else {set _txt "??"} }
      PRES { if {[info exists Stations($sta,metar,airpressure)]} {set _txt $Stations($sta,metar,airpressure)} else {set _txt "????"} }
      WTHR {
        set _txt ""
        if {[info exists Stations($sta,metar,weather)]} {
          foreach _E1 $Stations($sta,metar,weather) {
            set _txt1 [join $_E1 ""]
            lappend _txt $_txt1
          }
        } else {
          set _txt "?????"
        }
      }
      default {set _txt "error"}
    }
    set _txt [string map {"<unknown>" "??"} $_txt]
    set _txt [string range $_txt 0 [expr $env(COLUMNS)-$clon-25]]
    puts -nonewline "$_col\033\[[expr $clat+2]\;[expr $clon+23]H¤$_txt"
  }

  puts -nonewline "\033\[0m\033\[[expr $env(LINES)-1]\;0H"
  flush stdout
}


proc lon2c {lon_deg} {
global Map

  return [expr round(1.00*($lon_deg-$Map(view,left))*$Map(view,charperdeg))]
}


proc lat2c {lat_deg} {
global Map

  return [expr round(1.00*($Map(view,top)-$lat_deg)*$Map(view,charperdeg)*0.85)]
}


proc interpolate_line {_List _Item} {

  if {[llength $_List] == 0} {return [list $_Item]}
  set _Last [lindex $_List end]
  if {$_Last == $_Item} {return $_List}
  foreach {slat slon} $_Last {}
  foreach {elat elon} $_Item {}
  set dlat [expr $elat-$slat] ; set dlon [expr $elon-$slon]


  if {[expr abs($dlat)] < [expr abs($dlon)]} {
    if {$dlon > 0} {
      for {set _s 0} {$_s <= $dlon} {incr _s} {
        set clon [expr $slon + $_s] ; set clat [expr $slat + $_s * $dlat / $dlon]
        set citem [list $clat $clon] ; if {$citem != [lindex $_List end]} {lappend _List $citem}
      }
    } else {
      for {set _s 0} {$_s >= $dlon} {incr _s -1} {
        set clon [expr $slon + $_s] ; set clat [expr $slat + $_s * $dlat / $dlon]
        set citem [list $clat $clon] ; if {$citem != [lindex $_List end]} {lappend _List $citem}
      }
    }
  } else {
    if {$dlat > 0} {
      for {set _s 0} {$_s <= $dlat} {incr _s} {
        set clon [expr $slon + $_s * $dlon / $dlat] ; set clat [expr $slat + $_s]
        set citem [list $clat $clon] ; if {$citem != [lindex $_List end]} {lappend _List $citem}
      }
    } else {
      for {set _s 0} {$_s >= $dlat} {incr _s -1} {
        set clon [expr $slon + $_s * $dlon / $dlat] ; set clat [expr $slat + $_s]
        set citem [list $clat $clon] ; if {$citem != [lindex $_List end]} {lappend _List $citem}
      }
    }
  }

  if {[lindex $_List end] != $_Item} {lappend _List $_Item}
  return $_List
}

########## MAIN PART ##########


load_map_files
reload_station_data
#retrieve_metar_data_to_file
reload_metar_data
redrawscreen

set Stay_in 1
while {$Stay_in} {
  set Command [gets stdin]
  switch -nocase -- [lindex $Command 0] {
    "RETRIEVE" {
      set mask [lindex $Command 1]
      if {![string length $mask]} {
        redrawscreen
        puts "\033\[1;31m*** Usage: RETRIEVE <STATION_ICAO|MASK_FOR_MULTIPLE_ICAOS>\033\[0m"
      } else {
        retrieve_metar_data_to_file $mask
      }
    }
    "RELOAD" {
      reload_metar_data
      redrawscreen
    }
    "REFRESH" {
      redrawscreen
    }
    "GO" {
      set Param [lindex $Command 1]
      switch -nocase -- $Param {
        "N" - "NORTH" - "U" - "UP" {
          set Map(view,top) [expr $Map(view,top)-($Map(view,bottom)-$Map(view,top))*0.25]
          redrawscreen
        }
        "S" - "SOUTH" - "D" - "DOWN" {
          set Map(view,top) [expr $Map(view,top)+($Map(view,bottom)-$Map(view,top))*0.25]
          redrawscreen
        }
        "W" - "WEST" - "L" - "LEFT" {
          set Map(view,left) [expr $Map(view,left)-($Map(view,right)-$Map(view,left))*0.25]
          redrawscreen
        }
        "E" - "EAST" - "R" - "RIGHT" {
          set Map(view,left) [expr $Map(view,left)+($Map(view,right)-$Map(view,left))*0.25]
          redrawscreen
        }
        default {
          redrawscreen
          puts "\033\[1;31m*** Direction not understood!\033\[0m"
        }
      }
    }
    "GOTO" {
      set gotosta [lindex $Command 1]
      if {(![string length $gotosta]) || ([lsearch -exact $Stations(_) $gotosta] == -1)} {
        redrawscreen
        puts "\033\[1;31m*** Usage: GOTO <STATION_ICAO>\033\[0m"
      } else {
        set Map(view,left) [expr $Stations($gotosta,Lon)-($Map(view,right)-$Map(view,left))*0.5]
        set Map(view,top)  [expr $Stations($gotosta,Lat)-($Map(view,bottom)-$Map(view,top))*0.5]
        set Curr(Station) $gotosta
        redrawscreen
      }
    }
    "ZOOM" {
      set Param [lindex $Command 1]
      switch -nocase -- $Param {
        IN {
          set Map(view,charperdeg) [expr $Map(view,charperdeg)*1.4142]
          redrawscreen
        }
        OUT {
          set Map(view,charperdeg) [expr $Map(view,charperdeg)/1.4142]
          redrawscreen
        }
        default {
          redrawscreen
          puts "\033\[1;31m*** Usage: ZOOM <IN|OUT>\033\[0m"
        }
      }
    }
    "LABEL" {
      set Param [string toupper [lindex $Command 1]]
      if {[lsearch -exact {ICAO TEMP WIND PRES WTHR} $Param] == -1} {
        redrawscreen
        puts "\033\[1;31m*** Usage: LABEL <ICAO|TEMP|WIND|PRES|WTHR>\033\[0m"
      } else {
        set Curr(LabelMode) $Param
        redrawscreen
      }
    }
    "QUIT" - "EXIT" {
      puts "\033\[2J"
      set Stay_in 0
    }
    default {
      redrawscreen
      puts "\033\[1;31m*** Command not understood!\033\[0m"
    }
  }
}

#+++ Ha a datum regi a fajlban, akkor is pirosnak vegye az allomast
#+++ Konkav feluleteket megcsinalni  (Balaton, Isztria, egyeb)
#+++ Mecsek hogyhogy azonnal magas?
#+++ Hegysegek tul darabosak
#+++ Valami meretskala a jobb also sarokba
