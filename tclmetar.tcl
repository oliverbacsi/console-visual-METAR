
namespace eval ::tclmetar {
    variable ftpsock
    variable metar_keys {abbrev raw year month day hour minute corrected winddir winddirstr windspeed windgust windvarfrom windvarfromstr windvarto windvartostr temperature dewpoint airpressure cloudstype cloudsheight toweringcumulus cumulonimbus weather visibility}
}

proc ::tclmetar::get_winddirstr { winddir } {
    if { [string is integer -strict $winddir] } {
        set wsi [expr {int(($winddir+11.25)/22.5)}]
        return [lindex {N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW N} $wsi]
    }
    return $winddir
}

proc ::tclmetar::parse_wind { f wd winddirnm winddirstrnm ws windspeednm wg windgustnm wu } {
    upvar $winddirnm    winddir
    upvar $winddirstrnm winddirstr
    upvar $windspeednm  windspeed
    upvar $windgustnm   windgust
    set winddir   [string trimleft $wd "0"] ; if { [string length $winddir]   == 0 } { set winddir 0 }
    set windspeed [string trimleft $ws "0"] ; if { [string length $windspeed] == 0 } { set windspeed 0 }
    set windgust  [string trimleft [string range $wg 1 end] "0"] ; if { [string length $windgust] == 0 } { set windgust 0 }
    switch -exact -- $wu {
        "KT" {
            set windspeed [expr {round($windspeed * 1.852)}]
            set windgust  [expr {round($windgust  * 1.852)}]
        }
        "MPS" {
            set windspeed [expr {round($windspeed * 3.6)}]
            set windgust  [expr {round($windgust  * 3.6)}]
        }
        "KMH" {
        }
        "KM" {
        }
    }
    set winddirstr [get_winddirstr $winddir]
}

proc ::tclmetar::parse_wind_variability { wvf windvarfromnm windvarfromstrnm wvt windvartonm windvartostrnm } {
    upvar $windvarfromnm    windvarfrom
    upvar $windvartonm      windvarto
    upvar $windvarfromstrnm windvarfromstr
    upvar $windvartostrnm   windvartostr
    set windvarfrom [string trimleft $wvf "0"] ; if { [string length $windvarfrom] == 0 } { set windvarfrom 0}
    set windvarfromstr [get_winddirstr $windvarfrom]
    set windvarto   [string trimleft $wvt "0"] ; if { [string length $windvarto]   == 0 } { set windvarto 0}
    set windvartostr [get_winddirstr $windvarto]
}

proc ::tclmetar::parse_temperature { f tempnm } {
    upvar $tempnm temp
    if { [string match "M*" $f] } {
        set temp -[string trimleft [string range $f 1 end] "0"] ; if { [string equal $temp "-"] } { set temp "0"}
    } else {
        set temp [string trimleft $f "0"] ; if { [string length $temp] == 0 } { set temp "0" }
    }
}

proc ::tclmetar::parse_air_pressure { pv airpressurenm pu } {
    upvar $airpressurenm airpressure
    switch -exact -- $pu {
        "A" {
            set airpressure [string trimleft [string range $pv 0 1] "0"].[string range $pv 2 3]
            set airpressure [string range [expr {$airpressure * 0.033864}] 0 4]
        }
        "Q" {
            set airpressure [string range [expr {[string trimleft $pv "0"] / 1000.0}] 0 4]
        }
    }
}

proc ::tclmetar::parse_clouds { ct cloudstypenm ch cloudsheightnm cbtcu toweringcumulusnm cumulonimbusnm } {
    upvar $cloudstypenm      cloudstype
    upvar $cloudsheightnm    cloudsheight
    upvar $toweringcumulusnm toweringcumulus
    upvar $cumulonimbusnm    cumulonimbus
    switch -exact -- $ct {
        SKC - CLR - NSC {
            if { [string equal $cloudstype "<unknown>"] } { set cloudstype SKC } else { lappend cloudstype SKC }
        }
        FEW - SCT - BKN - OVC {
            if { [string equal $cloudstype "<unknown>"] } { set cloudstype $ct } else { lappend cloudstype $ct }
        }
    }
    set ch [string trimleft $ch "0"]
    if { [string length $ch] == 0 } { set ch "0" }
    if { [string equal $cloudsheight "<unknown>"] } { set cloudsheight [expr {round($ch * 30.48)}] } else { lappend cloudsheight [expr {round($ch * 30.48)}] }
    switch -exact -- $cbtcu {
        CB {
            set toweringcumulus 0 ; set cumulonimbus 1
        }
        TCU {
            set toweringcumulus 1 ; set cumulonimbus 0
        }
        default {
            set toweringcumulus 0 ; set cumulonimbus 0
        }
    }
}

proc ::tclmetar::parse_weather { int vic desc wea weathernm } {
    upvar $weathernm weather
    set wl [list $int $vic $desc $wea]
    if { [string equal $weather "<unknown>"] } { set weather [list $wl] } else { lappend weather $wl }
}

proc ::tclmetar::parse_international_visibility { m visibilitynm } {
    upvar $visibilitynm visibility
    set visibility [string trimleft $m "0"] ; if { [string length $visibility] == 0 } { set visibility 0 }
}

proc ::tclmetar::parse_american_visibility { v1 v2 prevf visibilitynm } {
    upvar $visibilitynm visibility
    if { ([string length $v2] == 0) || [string equal $v2 "0"] } { set v2 1 }
    append v2 ".0"
    if { ![string is integer -strict $prevf] } { set prevf 0 }
    set visibility [string range [expr {($prevf + $v1/$v2) * 1609.34}] 0 7]
}

proc ::tclmetar::parse { metarl mi_abbrev } {

    array set MetAbbrev {
      "-" "Light:" "+" "Heavy:" VC "Vicinity:" MI "Shallow" PR "Partial" BC "Patches" DR "Drifting" BL "Blowing" SH "Showering" TS "ThunderStorm" FZ "Frozen" RE "Recent" \
      RA "Rain" DZ "Drizzle" SN "Snow" SG "SnowGrains" IC "IceCrystals" PL "IcePellets" GR "HailStorm" GS "HailPellets" UP "Precipitation" \
      FG "Fog" VA "VolcanicAsh" BR "Mist" HZ "Haze" DU "Dust" FU "Smoke" SA "Sand" PY "Spray" SQ "Squall" PO "DustDevil" DS "DustStorm" SS "SandStorm" FC "FunnelCloud" NOSIG "NOSIG\033\[0;33mnificantchange" \
      RMK "\033\[0m\033\[1;37mR\033\[0;37me\033\[1;37mM\033\[0;37mar\033\[1;37mK" AUTO "\033\[0m\033\[1;37mAuto\033\[0;37mmaticReport" MANU "\033\[0m\033\[1;37mManu\033\[0;37mallyCorrected" COR "\033\[0m\033\[0;37mManually\033\[1;37mCor\033\[0;37mrected" CORR "\033\[0m\033\[0;37mManually\033\[1;37mCorr\033\[0;37mected" TEMPO "\033\[0m\033\[1;37mTEMPO\033\[0;37mrarily" BECMG "\033\[0m\033\[1;37mBEC\033\[0;37mo\033\[1;37mM\033\[0;37min\033\[1;37mG" \
      CAVOK "C\033\[0;36mlouds\033\[1;36mA\033\[0;36mnd\033\[1;36mV\033\[0;36misibility\033\[1;36mOK" SKC "Sk\033\[0;36my\033\[1;36mC\033\[0;36mlear" FEW "FEW" SCT "SC\033\[0;36mat\033\[1;36mT\033\[0;36mered" BKN "B\033\[0;36mro\033\[1;36mK\033\[0;36me\033\[1;36mN" OVC "OV\033\[0;36mer\033\[1;36mC\033\[0;36mast" CLR "CL\033\[0;36mea\033\[1;36mR\033\[0;36msky" NSC "N\033\[0;36mo\033\[1;36mS\033\[0;36mignificant\033\[1;36mC\033\[0;36mloud" CB "C\033\[0;31mumulonim\033\[1;31mB\033\[0;31mus" TCU "T\033\[0;31mowering\033\[1;31mCU\033\[0;31mmulus" \
      BLU "Blue Code" WHT "White Code" GRN "Green Code" YLO "Yellow Code" AMB "Amber Code" RED "Red Code" \
    }
    set ar(abbrev)          $mi_abbrev
    set ar(raw)             $metarl
    set ar(year)            "<unknown>"
    set ar(month)           "<unknown>"
    set ar(day)             "<unknown>"
    set ar(hour)            "<unknown>"
    set ar(minute)          "<unknown>"
    set ar(corrected)       "<unknown>" ;# bool
    set ar(winddir)         "<unknown>" ;# 0 = north, 90 = east
    set ar(winddirstr)      "<unknown>"
    set ar(windspeed)       "<unknown>" ;# in km/h
    set ar(windgust)        "<unknown>" ;# in km/h
    set ar(windvarfrom)     "<unknown>" ;# 0 = north, 90 = east
    set ar(windvarfromstr)  "<unknown>" ;# 0 = north, 90 = east
    set ar(windvarto)       "<unknown>" ;# 0 = north, 90 = east
    set ar(windvartostr)    "<unknown>" ;# 0 = north, 90 = east
    set ar(temperature)     "<unknown>" ;# in degrees Celcius
    set ar(dewpoint)        "<unknown>" ;# in degrees Celcius
    set ar(airpressure)     "<unknown>" ;# in bar
    set ar(cloudstype)      "<unknown>" ;# list of SKC (sky clear) | FEW | SCT (scattered) | BKN (broken) | OVC (overcast) | CAVOK
    set ar(cloudsheight)    "<unknown>" ;# list of heights in meter | CAVOK
    set ar(toweringcumulus) "<unknown>" ;# bool
    set ar(cumulonimbus)    "<unknown>" ;# bool
    set ar(weather)         "<unknown>" ;# in metar abbreviations
    set ar(visibility)      "<unknown>" ;# in meter
    set ar(ansi_raw)        ""
    set ar(ansi_eur)        ""

    set prevf ""
    set mi_abbrev_found 0

    foreach f $metarl {
        if { [string equal $mi_abbrev $f] } {
            set mi_abbrev_found 1
            continue
        }
        if { !$mi_abbrev_found && [regexp {([0-9]{4})/([0-9]{2})/([0-9]{2})} $f ma y m d] } {
            set ar(year)  [string trimleft $y "0"]
            set ar(month) [string trimleft $m "0"]
            set ar(day)   [string trimleft $d "0"]
            append ar(ansi_raw) "\033\[1m@\033\[0m$y\033\[1m/\033\[0m$m\033\[1m/\033\[0m$d "
            append ar(ansi_eur) "\033\[1m@\033\[0m$ar(month)\033\[1m/\033\[0m$ar(day) "
        } elseif { !$mi_abbrev_found && [regexp {([0-9]{2}):([0-9]{2})} $f ma h m] } {
            set ar(hour)   [string trimleft $h "0"] ; if { [string length $ar(hour)]   == 0 } { set ar(hour) 0 }
            set ar(minute) [string trimleft $m "0"] ; if { [string length $ar(minute)] == 0 } { set ar(minute) 0 }
            append ar(ansi_raw) "\033\[1m@\033\[0m$h\033\[1m:\033\[0m$m "
            append ar(ansi_eur) "\033\[1m@\033\[0m$ar(hour)\033\[1m:\033\[0m$ar(minute) "
        } elseif { !$mi_abbrev_found } {
            continue
        } elseif { [string match "RMK*" $f] || [string match "TEMP*" $f] || [string match "BECMG*" $f]} {
            append ar(ansi_raw) "\033\[0;30;47m$f\033\[0m "
            append ar(ansi_eur) "\033\[0;30;47m$MetAbbrev($f)\033\[0m "
            #break
        } elseif { [regexp {([0-9][0-9])([0-9][0-9])([0-9][0-9])Z} $f ma d h m] } {
            # Date/time field
            set _now [clock seconds]
            set ar(day)    [string trimleft $d "0"]
            set ar(hour)   [string trimleft $h "0"] ; if { [string length $ar(hour)]   == 0 } { set ar(hour) 0 }
            set ar(minute) [string trimleft $m "0"] ; if { [string length $ar(minute)] == 0 } { set ar(minute) 0 }
            set ar(month)  [string trimleft [clock format $_now -format %m] "0"]
            set ar(year)   [clock format $_now -format %Y]
            if {$d > [clock format $_now -format %d]} {incr ar(month) -1 ; if {$ar(month) < 1} {set ar(month) 12 ; incr ar(year) -1}}
            append ar(ansi_raw) "\033\[1m@\033\[0m$d$h$m\033\[1mZ\033\[0m "
            set _ti [get_time ar]
            append ar(ansi_eur) "\033\[1m@\033\[0m[clock format $_ti -format %d]\033\[1m/\033\[0m[clock format $_ti -format %H]\033\[1m:\033\[0m[clock format $_ti -format %M] "
        } elseif { [string match "COR*" $f] } {
            append ar(ansi_raw) "\033\[0;30;47m$f\033\[0m "
            append ar(ansi_eur) "\033\[0;30;47m$MetAbbrev($f)\033\[0m "
            set ar(corrected) 1
        } elseif { [string match "AUT*" $f] } {
            append ar(ansi_raw) "\033\[0;30;47m$f\033\[0m "
            append ar(ansi_eur) "\033\[0;30;47m$MetAbbrev($f)\033\[0m "
            set ar(corrected) 0
        } elseif { [string match {R[0-9][0-9][LCR]*} $f] } {
            # Runway visibility still to be added
            append ar(ansi_raw) "\033\[1;32;42m[string range $f 0 3]\033\[0;32m[string range $f 4 end]\033\[0m "
            append ar(ansi_eur) "\033\[1;32;42mRWY\033\[0;32m[string range $f 4 end]\033\[0m "
        } elseif { [regexp {([0-9]{3}|VRB)?([0-9]{2,3})(G[0-9]{2,3})?(KT|KMH|MPS|KM)} $f m wd ws wg wu] } {
            # Wind field
            parse_wind $f $wd ar(winddir) ar(winddirstr) $ws ar(windspeed) $wg ar(windgust) $wu
            append ar(ansi_eur) "\033\[0;34m$ar(winddirstr)\033\[1;34m$ar(windspeed)"
            append ar(ansi_raw) "\033\[0;34m$wd\033\[1;34m$ws"
            if {$ar(windgust)} {
              append ar(ansi_eur) "\033\[0;34mG\033\[1;34m$ar(windgust)"
              append ar(ansi_raw) "\033\[0;34mG\033\[1;34m[string range $wg 1 end]"
            }
            append ar(ansi_eur) "\033\[0;34mKMH\033\[0m "
            append ar(ansi_raw) "\033\[0;34m$wu\033\[0m "
        } elseif { [regexp {(\/{4})(KT|KMH|MPS)} $f m ws wu] } {
            append ar(ansi_raw) "\033\[1;34m$ws\033\[0;34m$wu "
            append ar(ansi_eur) "\033\[1;34mNo Wind "
        } elseif { [regexp {([0-9]{3})V([0-9]{3})} $f m wvf wvt] } {
            # Wind variability
            parse_wind_variability $wvf ar(windvarfrom) ar(windvarfromstr) $wvt ar(windvarto) ar(windvartostr)
            append ar(ansi_eur) "\033\[0;34m$ar(windvarfromstr)\033\[1;34m\-\033\[0;34m$ar(windvartostr)\033\[0m "
            append ar(ansi_raw) "\033\[0;34m$wvf\033\[1;34mV\033\[0;34m$wvt\033\[0m "
        } elseif { [regexp {^(M?[0-9][0-9])/+(M?[0-9][0-9])$} $f m temp dewp] } {
            # Temperature field
            parse_temperature $temp ar(temperature)
            parse_temperature $dewp ar(dewpoint)
            append ar(ansi_eur) "\033\[1;32m$ar(temperature)C\033\[0;32m/$ar(dewpoint)dew\033\[0m "
            append ar(ansi_raw) "\033\[1;32m$ar(temperature)\033\[0;32m/$ar(dewpoint)\033\[0m "
        } elseif { [regexp {(A|Q)([0-9]{4})} $f m pu pv] } {
            # Altimeter settings field
            parse_air_pressure $pv ar(airpressure) $pu
            append ar(ansi_raw) "\033\[0;35m$pu\033\[1;35m$pv\033\[0m "
            append ar(ansi_eur) "\033\[1;35m$ar(airpressure)\033\[0;35mbar\033\[0m "
        } elseif { [regexp {(SKC|FEW|SCT|BKN|OVC|CLR|NSC)([0-9]{3})?(CB|TCU)?} $f m ct ch cbtcu] } {
            # Clouds field
            parse_clouds $ct ar(cloudstype) $ch ar(cloudsheight) $cbtcu ar(toweringcumulus) ar(cumulonimbus)
            append ar(ansi_raw) "\033\[1;36m$ct\033\[0;36m$ch"
            append ar(ansi_eur) "\033\[1;36m$MetAbbrev([lindex $ar(cloudstype) end])\033\[0;36m[lindex $ar(cloudsheight) end]m"
            if {[string length $cbtcu]} {
              append ar(ansi_raw) "\033\[0;31m\[\033\[1;31m$cbtcu\033\[0;31m\]\033\[0m "
              append ar(ansi_eur) "\033\[0;31m\[\033\[1;31m$MetAbbrev($cbtcu)\033\[0;31m\]\033\[0m "
            } else {
              append ar(ansi_raw) "\033\[0m "
              append ar(ansi_eur) "\033\[0m "
            }
        } elseif { [string equal $f "CAVOK"] } {
            set ar(cloudstype) "CAVOK"
            set ar(cloudsheight) "CAVOK"
            set ar(cumulonimbus) 0
            set ar(toweringcumulus) 0
            set ar(visibility) 9999
            append ar(ansi_raw) "\033\[1;36m$f\033\[0m "
            append ar(ansi_eur) "\033\[1;36m$MetAbbrev($f)\033\[0m "
        } elseif { [regexp {([\+\-]?)(VC)?(MI|BC|PR|TS|BL|SH|DR|FZ|RE)?(DZ|RA|SN|SG|IC|PL|GR|GS|UP|FG|VA|BR|HZ|DU|FU|SA|PY|SQ|PO|DS|SS|TS|FC|\+FC|NOSIG|SH)} $f m int vic desc wea] } {
            # Weather field
            parse_weather $int $vic $desc $wea ar(weather)
            if {[string length $int]} {
              if {"$int" eq "+"} { append ar(ansi_raw) "\033\[1;31m$int" ; append ar(ansi_eur) "\033\[1;31m$MetAbbrev($int)" } else { append ar(ansi_raw) "\033\[1;32m$int" ; append ar(ansi_eur) "\033\[1;32m$MetAbbrev($int)" }
            }
            if {[string length $vic]} {
              append ar(ansi_raw) "\033\[0m$vic" ; append ar(ansi_eur) "\033\[0m$MetAbbrev($vic)"
            }
            if {[string length $desc]} {
              if {"$desc" eq "TS"} {set _col "\033\[1;31m"} elseif {"$desc" eq "FZ"} {set _col "\033\[1;34m"} elseif {"$desc" eq "RE"} {set _col "\033\[1;30m"} else {set _col "\033\[1;33m"}
              append ar(ansi_raw) "$_col$desc" ; append ar(ansi_eur) "$_col$MetAbbrev($desc)"
            }
            if {[string length $wea]} {
              if {("$wea" eq "GR") || ("$wea" eq "GS") || ("$wea" eq "FC") || ("$wea" eq "TS")} {set _col "\033\[1;31m"} else {set _col "\033\[1;33m"}
              append ar(ansi_raw) "$_col$wea\033\[0m " ; append ar(ansi_eur) "$_col$MetAbbrev($wea)\033\[0m "
            }
            while { 1 } {
                set f [string range $f [string length $m] end]
                if { ![regexp {([\+\-]?)(VC)?(MI|BC|PR|TS|BL|SH|DR|FZ|RE)?(DZ|RA|SN|SG|IC|PL|GR|GS|UP|FG|VA|BR|HZ|DU|FU|SA|PY|SQ|PO|DS|SS|TS|FC|\+FC|NOSIG|SH)} $f m int vic desc wea] } {
                    break
                }
                parse_weather $int $vic $desc $wea ar(weather)
                if {[string length $int]} {
                  if {"$int" eq "+"} { append ar(ansi_raw) "\033\[1;31m$int" ; append ar(ansi_eur) "\033\[1;31m$MetAbbrev($int)" } else { append ar(ansi_raw) "\033\[1;32m$int" ; append ar(ansi_eur) "\033\[1;32m$MetAbbrev($int)" }
                }
                if {[string length $vic]} {
                  append ar(ansi_raw) "\033\[0m$vic" ; append ar(ansi_eur) "\033\[0m$MetAbbrev($vic)"
                }
                if {[string length $desc]} {
                  if {"$desc" eq "TS"} {set _col "\033\[1;31m"} elseif {"$desc" eq "FZ"} {set _col "\033\[1;34m"} elseif {"$desc" eq "RE"} {set _col "\033\[1;30m"} else {set _col "\033\[1;33m"}
                  append ar(ansi_raw) "$_col$desc" ; append ar(ansi_eur) "$_col$MetAbbrev($desc)"
                }
                if {[string length $wea]} {
                  if {("$wea" eq "GR") || ("$wea" eq "GS") || ("$wea" eq "FC") || ("$wea" eq "TS")} {set _col "\033\[1;31m"} else {set _col "\033\[1;33m"}
                  append ar(ansi_raw) "$_col$wea\033\[0m " ; append ar(ansi_eur) "$_col$MetAbbrev($wea)\033\[0m "
                }
            }
        } elseif { [regexp {^[0-9]{4}$} $f m ] } {
            # International visibility field
            parse_international_visibility $m ar(visibility)
            append ar(ansi_raw) "\033\[0;33m$m\033\[0m "
            append ar(ansi_eur) "\033\[0mVis:\033\[0;33m$ar(visibility)\033\[0m "
        } elseif { [regexp {^([0-9]{1,2})/?([0-9]{0,2})SM$} $f m v1 v2] } {
            # American visibility field
            parse_american_visibility $v1 $v2 $prevf ar(visibility)
            append ar(ansi_raw) "\033\[0;33m$m\033\[0m "
            append ar(ansi_eur) "\033\[0mVis:\033\[0;33m$ar(visibility)\033\[0m "
        } else {
          append ar(ansi_raw) "\033\[0m$f "
          if {[info exists MetAbbrev($f)]} { append ar(ansi_eur) "\033\[0m$MetAbbrev($f) " } else { append ar(ansi_eur) "\033\[0m$f " }
        }
        # Visibility directions still to be added

        set prevf $f
    }

    if {[string match -nocase *unkn* $ar(corrected)]} {
      set _station "\033\[1m\<\033\[0m$mi_abbrev\033\[1m\>\033\[0m"
    } elseif {"$ar(corrected)" eq "1"} {
      set _station "\033\[1m\~\033\[0m$mi_abbrev\033\[1m\~\033\[0m"
    } else {
      set _station "\033\[1m\[\033\[0m$mi_abbrev\033\[1m\]\033\[0m"
    }
    set ar(ansi_eur) "$_station $ar(ansi_eur)"
    set ar(ansi_raw) "$_station $ar(ansi_raw)"

    return [array get ar]
}

proc ::tclmetar::get_time { arnm } {
    upvar $arnm ar
    set y $ar(year)   ; while { [string length $y] < 4 } { set y "0$y" }
    set M $ar(month)  ; while { [string length $M] < 2 } { set M "0$M" }
    set d $ar(day)    ; while { [string length $d] < 2 } { set d "0$d" }
    set h $ar(hour)   ; while { [string length $h] < 2 } { set h "0$h" }
    set h "T$h"
    set m $ar(minute) ; while { [string length $m] < 2 } { set m "0$m" }
    set s "00"
    set mt [clock scan "$y$M$d$h$m$s" -gmt true]
    return $mt
}
