#!/usr/bin/tclsh
#
# atd_map.tcl
#
# How to run it:   ./atd_map.tcl atd_script.inp [native/GLY/ALA/...] [ temp_min ] [ temp_max ]
#
# Where "atd_script.inp" the input file.
#
#       native/GLY/ALA/... is the mutant to be considered.
#
#
#       temp_min and temp_max are the minimum and maximum temperatures of the
#       of the scale that will be used to define colors. If these values are
#       not set, default parameters of temp_min=0K and temp_max=thermalization temperature
#       will be used.
#
# This scripts reads the temperatures.dat files of every residue
# of a given set of simulations and creates xmgrace files with 
# the contact map and with the thermal diffusion map of the
# structure
#
# This script will compute the side chain contributions 
# for the mutant selected
#
# L. Martinez, Aug 28, 2009.
#

source ATD_SCRIPTS_DIR/bin/atd_procs.tcl

puts " ---------------------------------------------- "
puts " ATD_MAP output. "
puts " ---------------------------------------------- "

array set arg [ check_args $argv "map" ]

source ATD_SCRIPTS_DIR/bin/atd_common.tcl

# Get temperature range if it was set

set temp_min -1
set temp_max -1
if { [ info exists arg(3) ] == 1 } {
  set temp_min $arg(3)
}
if { [ info exists arg(4) ] == 1 } {
  set temp_max $arg(4)
}

# Set association between temperature and colors in xmgrace

proc temperature_color { temperature temp_min temp_max } {

  set temperature [ expr ( $temperature - $temp_min ) / ( $temp_max - $temp_min ) ]
  if { $temperature > 1 } { set temperature 1 }
  set temperature [ expr $temperature * 26 ]
  set temperature [ expr 199 + $temperature ]

  set temperature_color [ format %3.0f $temperature ]
  return $temperature_color

}

puts " ---------------------------------------------- "
if { $native } {
  puts " Computing thermal diffusion map for native simulation. "
} else {
  puts " Computing thermal diffusion map for $mutation mutant simulations. "
}

# Creating directory that will contain the final data and graphics

exec mkdir -p $output_dir/data
exec mkdir -p $output_dir/graphs

puts " Getting data from temperatures.dat files and creating graphs... "

# From the NAMD input file, get the temperature to which the residue
# was heated to set the color scale

set file [ open $namdinput r ]
set namdinput [ read $file ]
close $file
set namdinput [ split $namdinput "\n" ]
foreach line $namdinput {
  if { [ string range $line 0 0 ] != "#" & 
       [ string first "langevinTemp" $line ] != -1 } {
    array set words [ parse_line $line " " ]
    set therm_temp $words(2)
  }
} 
if { [ info exists therm_temp ] == 0 } {
  puts " ERROR: Could not find langevinTemp keyword in namd input file. "
  exit
}
puts " Residues were thermalized to $therm_temp K"

# If the range was not set on running time, use default values: 

if { $temp_min == -1 | $temp_max == -1 } { 
  set $temp_min 0.
  set $temp_max [ expr 0.7 * $therm_temp ] 
  puts "Warning: using default temperature range: 0. $temp_max for colors."
} else { 
  puts " Temperature range to set colors: ($temp_min, $temp_max) K "

}

# Reading temperatures.dat files, getting data and reading the graphs

set file [ open ATD_SCRIPTS_DIR/xmgrace/map.agr r ] 
set xmgrace_base [ read $file ]
close $file
set xmgrace_base [ split $xmgrace_base "\n" ]

if { $native } {
  set map $output_dir/graphs/native_map.agr
  puts " Creating $map "
} else {
  set map $output_dir/graphs/to_$mutation\_map.agr
  puts " Creating $map "
}
set graph [ open $map w ]

foreach graph_line $xmgrace_base {
  
  if { [ string first "INSERT_THERMAL_DATA" $graph_line ] != -1 } {
    for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
      progress $i_resid $n_resid
      set failed($i_resid) 0
      if { $native } {
        set temperatures [ nat_dir $i_resid ]/temperatures.dat
      } else {
        set temperatures [ mut_dir $i_resid ]/temperatures.dat
      } 
      if { [ file isfile $temperatures ] == 1 } {
        set file [ open $temperatures r ]
        set temperatures [ read $file ]
        close $file
        set temperatures [ split $temperatures "\n" ]
        foreach line $temperatures { 
          if { [ string range $line 0 0 ] != "#" &
               [ string trim $line ] > " " } { 
            array set words [ parse_line $line " " ] 
            set color [ temperature_color $words(2) $temp_min $temp_max ]
            puts $graph "$resid($i_resid)  $words(1)  $color"
          }
        }
      }
    }
  } elseif { [ string first "INSERT_CONTACT_MAP" $graph_line ] != -1 } {
    set contacts [ exec ATD_SCRIPTS_DIR/bin/contacts $pdb_file_name $mutate_segment ]
    puts $graph $contacts
  } else {
    puts $graph $graph_line
  }
}

puts " ---------------------------------------------- "
puts " Normal termination of ATD_MAP script. "
puts " ---------------------------------------------- "













