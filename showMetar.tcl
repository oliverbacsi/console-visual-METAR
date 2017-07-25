#!/usr/bin/tclsh

#lappend auto_path ../../_alien/tclmetar-0.1/
#package require tclmetar

########## INIT PART ##########

package require ftp
source tclmetar.tcl
array set Stations {_ {}} ; global Stations
global env


########## PROC PART ##########

proc retrieve_metar_data_to_file {} {
global Stations
variable ftpsock

  set ::ftp::VERBOSE 1
  set ftpsock [::ftp::Open "tgftp.nws.noaa.gov" anonymous anonymous]
  ::ftp::Cd $ftpsock "data/observations/metar/stations"
  foreach sta $Stations(_) {
    set fout [open _data/$sta.TXT w]
    catch {set rt [::ftp::Get $ftpsock $sta.TXT -channel $fout]}
    close $fout
  }
  catch {::ftp::Close $ftpsock}
}


proc reload_station_data {} {
global Stations

  set fin [open CloseStations.txt r] ; gets $fin
  while {![eof $fin]} {
    set sList [split [gets $fin] ";"]
    if {[llength $sList] < 4} continue
    set ICAO [lindex $sList 0]
    lappend Stations(_) $ICAO
    set Stations($ICAO,Dsc) [lindex $sList 1]
    set Stations($ICAO,Lat) [lindex $sList 2]
    set Stations($ICAO,Lon) [lindex $sList 3]
    set Stations($ICAO,Alt) [lindex $sList 4]
    set Stations($ICAO,Dst) [lindex $sList 5]
    set Stations($ICAO,Dir) [lindex $sList 6]
  }
  close $fin
}


proc reload_metar_data {} {
global Stations

  foreach sta $Stations(_) {
    set fin [open "_data/$sta.TXT" r]
    gets $fin
#    set Stations($sta,Decoded) [::tclmetar::parse [gets $fin] $sta]
    array set _tempArray [::tclmetar::parse [gets $fin] $sta]
    close $fin
    foreach idx [array names _tempArray] {
      set Stations($sta,metar,$idx) "$_tempArray($idx)"
    }
  }
}

########## MAIN PART ##########


reload_station_data
#retrieve_metar_data_to_file
reload_metar_data


# Cut this shit
foreach sta $Stations(_) {
  puts $Stations($sta,metar,ansi_raw)
}
