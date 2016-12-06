#!/usr/bin/tclsh
#
# atd_sidechains.tcl
#
# How to run it:   ./atd_sidechains.tcl atd_script.inp [GLY/ALA/...]
#
# Where "atd_script.inp" the input file.
#
# and GLY/ALA/... is the mutant to be considered.
#
# This script analyses ATD simulations that were run with
# the atd_run.tcl script and for which the temperatures where
# already computed with the atd_temperatures.tcl script. 
# Relevant output files will be put at 
# the output/data and output/graphs directories.
#
# This script will compute the side chain contributions 
# for the mutant selected
#
# L. Martinez, Aug 28, 2009.
#

source ATD_SCRIPTS_DIR/bin/atd_procs.tcl

puts " ---------------------------------------------- "
puts " ATD_SIDECHAINS output. "
puts " ---------------------------------------------- "

array set arg [ check_args $argv "sidechains" ]

source ATD_SCRIPTS_DIR/bin/atd_common.tcl

# This script can only be run with a amino acid as input

if { $native } {
  puts " ERROR: Side chain contributions must be run for some "
  puts "        mutant set of simulations. The \"native\" simulations "
  puts "        are suposed to be present. "
  puts "        Therefore, \"native\" is not a valid argument. "
  puts "        Run with: atd_sidechains.tcl atd_script.inp \[GLY/ALA...\]"
  exit
}

puts " ---------------------------------------------- "
puts " Computing side chain contributions for $mutation mutants."

# Creating directory that will contain the final data and graphics

exec mkdir -p $output_dir/data
exec mkdir -p $output_dir/graphs

puts " Getting data from temperatures.dat files and creating graphs... "

# Maximum and minimum values are used to set the axis ranges

set max_average 0.
set min_average 1000000.
set max_final 0.
set min_final 1000000.
set max_diff_average -100000.
set min_diff_average 100000.
set max_diff_final -100000.
set min_diff_final 100000.

for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
 
  progress $i_resid $n_resid

# Native data 

  if { [ file isfile [ nat_dir $i_resid ]/temperatures.dat ] } { 
    set native_data [ nat_dir $i_resid ]/temperatures.dat
    set file [ open $native_data r ] 
    set native_data [ read $file ]
    close $file
    set native_data [ split $native_data "\n" ]
    foreach line $native_data {
      if { [ string first "# Final temperature:" $line ] != -1 } {
        set nat_final_temp($i_resid) \
            [ string trim [ string range $line 20 40 ] ]
        if { $nat_final_temp($i_resid) > $max_final } \
           { set max_final $nat_final_temp($i_resid) }  
        if { $nat_final_temp($i_resid) < $min_final } \
           { set min_final $nat_final_temp($i_resid) }  
      }
      if { [ string first "# Average temperature:" $line ] != -1 } {
        set nat_average_temp($i_resid) \
            [ string trim [ string range $line 22 42 ] ]
        if { $nat_average_temp($i_resid) > $max_average } \
           { set max_average $nat_average_temp($i_resid) }  
        if { $nat_average_temp($i_resid) < $min_average } \
           { set min_average $nat_average_temp($i_resid) }  
      }
    }
  }

# Mutants data 

  if { [ file isfile [ mut_dir $i_resid ]/temperatures.dat ] } {
    set mutant_data [ mut_dir $i_resid ]/temperatures.dat
    set file [ open $mutant_data r ] 
    set mutant_data [ read $file ]
    close $file
    set mutant_data [ split $mutant_data "\n" ]
    foreach line $mutant_data {
      if { [ string first "# Final temperature:" $line ] != -1 } {
        set mut_final_temp($i_resid) \
            [ string trim [ string range $line 20 40 ] ]
        if { $mut_final_temp($i_resid) > $max_final } \
           { set max_final $mut_final_temp($i_resid) }  
        if { $mut_final_temp($i_resid) < $min_final } \
           { set min_final $mut_final_temp($i_resid) }  
      }
      if { [ string first "# Average temperature:" $line ] != -1 } {
        set mut_average_temp($i_resid) \
            [ string trim [ string range $line 22 42 ] ]          
        if { $mut_average_temp($i_resid) > $max_average } \
           { set max_average $mut_average_temp($i_resid) }  
        if { $mut_average_temp($i_resid) < $min_average } \
           { set min_average $mut_average_temp($i_resid) }  
      }
    }
  }

  if { [ info exists nat_final_temp($i_resid) ] == 0 } {
    set nat_final_temp($i_resid) 0.
    set nat_average_temp($i_resid) 0.
    set failed_nat($i_resid) 1
  }
  if { [ info exists mut_final_temp($i_resid) ] == 0 } {
    set mut_final_temp($i_resid) 0.
    set mut_average_temp($i_resid) 0.
    set failed_mut($i_resid) 1
  }
  if { [ info exists failed_nat($i_resid) ] |
       [ info exists failed_mut($i_resid) ] } { 
    set scc_average($i_resid) 0.
    set scc_final($i_resid) 0.
    continue 
  }

  set scc_average($i_resid) \
  [ expr $nat_average_temp($i_resid) - $mut_average_temp($i_resid) ]
  set scc_final($i_resid) \
  [ expr $nat_final_temp($i_resid) - $mut_final_temp($i_resid) ]

  if { $scc_average($i_resid) > $max_diff_average } { set max_diff_average $scc_average($i_resid) }
  if { $scc_average($i_resid) < $min_diff_average } { set min_diff_average $scc_average($i_resid) }
  if { $scc_final($i_resid) > $max_diff_final } { set max_diff_final $scc_final($i_resid) }
  if { $scc_final($i_resid) < $min_diff_final } { set min_diff_final $scc_final($i_resid) }

}

#
# Writing the data to files
#

puts " Writing final data files in $output_dir/data"

set data_average [ open $output_dir/data/to_$mutation.side_chains_average.dat w ]
set data_final [ open $output_dir/data/to_$mutation.side_chains_final.dat w ]

puts $data_average "# Data of average structure heating
# Residue_Heated  Average_native_temp  Average_mutant_temp  Difference"
puts $data_final "# Data of final structure heating
# Residue_Heated  Final_native_temp  Final_mutant_temp  Difference"

for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {

  progress $i_resid $n_resid 

  puts $data_average \
  "$resname($i_resid) $resid($i_resid) [ format "%8.2f %8.2f %8.2f" \
  $nat_average_temp($i_resid) $mut_average_temp($i_resid) $scc_average($i_resid) ]"

  puts $data_final \
  "$resname($i_resid) $resid($i_resid) [ format "%8.2f %8.2f %8.2f" \
  $nat_final_temp($i_resid) $mut_final_temp($i_resid) $scc_final($i_resid) ]"

}

close $data_average
close $data_final

#
# Writing the xmgrace graphs 
#

puts " Writing xmgrace graph files in $output_dir/graphs"

# Increase the ranges by 1K 

set max_final [ expr $max_final + 1. ]
set min_final [ expr $min_final - 1. ]
set max_average [ expr $max_average + 1. ]
set min_average [ expr $min_average - 1. ]
set max_diff_average [ expr $max_diff_average + 1. ]
set min_diff_average [ expr $min_diff_average - 1. ]
set max_diff_final [ expr $max_diff_final + 1. ]
set min_diff_final [ expr $min_diff_final - 1. ]

# The x-range is from first to last residue

set x_min $resid(1)
set x_max $resid($n_resid)
if { $x_min == $x_max } { set x_max [ expr $x_max + 1 ] }

set xmgrace_base [ open ATD_SCRIPTS_DIR/xmgrace/side_chains.agr r ]
set graph_average [ open $output_dir/graphs/to_$mutation.side_chains_average.agr w ]
set graph_final [ open $output_dir/graphs/to_$mutation.side_chains_final.agr w ]
set file [ read $xmgrace_base ]
close $xmgrace_base
set xmgrace_base [ split $file "\n" ]
foreach line $xmgrace_base {

# Insert data

  if { [ string first "INSERT_DATA_NATIVE" $line ] != -1 } {
    for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
      if { [ info exists failed_nat($i_resid) ] } { continue } 
      set color [ color $resname($i_resid) ]
      puts $graph_average "$resid($i_resid) $nat_average_temp($i_resid) $color"
      puts $graph_final "$resid($i_resid) $nat_final_temp($i_resid) $color"
    }
  } elseif { [ string first "INSERT_DATA_MUTANTS" $line ] != -1 } {
    for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
      if { [ info exists failed_mut($i_resid) ] } { continue } 
      set color [ color $resname($i_resid) ]
      puts $graph_average "$resid($i_resid) $mut_average_temp($i_resid) $color"
      puts $graph_final "$resid($i_resid) $mut_final_temp($i_resid) $color"
    }
  } elseif { [ string first "INSERT_DATA_SIDE_CHAIN_CONTRIBUTIONS" $line ] != -1 } {
    for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
      if { [ info exists failed_nat($i_resid) ] |
           [ info exists failed_mut($i_resid) ] } { continue } 
      set color [ color $resname($i_resid) ]
      puts $graph_average "$resid($i_resid) $scc_average($i_resid) $color"
      puts $graph_final "$resid($i_resid) $scc_final($i_resid) $color"
    }

# Insert axis ranges

  } elseif { [ string first "INSERT_AXIS_NATIVE" $line ] != -1 } {
    puts $graph_average \
         "@    world $x_min, $min_average, $x_max, $max_average"
    puts $graph_final \
         "@    world $x_min, $min_final, $x_max, $max_final"
  } elseif { [ string first "INSERT_AXIS_MUTANTS" $line ] != -1 } {
    puts $graph_average \
         "@    world $x_min, $min_average, $x_max, $max_average"
    puts $graph_final \
         "@    world $x_min, $min_final, $x_max, $max_final"
  } elseif { [ string first "INSERT_AXIS_DIFF" $line ] != -1 } {
    puts $graph_average \
         "@    world $x_min, $min_diff_average, $x_max, $max_diff_average"
    puts $graph_final \
         "@    world $x_min, $min_diff_final, $x_max, $max_diff_final"

# Insert unchanged lines

  } else {

    puts $graph_average $line
    puts $graph_final [ string map [ list "Average" "Final" ] $line ]

  } 
}
close $graph_average
close $graph_final

# Ordering side-chain contributions from higher to lower

puts " Ordering side chain contributions from higher to lower... "
puts " Output is written in $output_dir/data directory"

for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
  set i_temp($i_resid) $i_resid
  set scc_temp($i_resid) $scc_final($i_resid)
}

for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
  set i_max $i_resid
  for { set j_resid [ expr $i_resid + 1 ] } { $j_resid <= $n_resid } { incr j_resid } {
    if { $scc_temp($j_resid) > $scc_temp($i_max) } {
      set i_max $j_resid
    } 
  }
  set i_scc($i_resid) $i_temp($i_max)
  set scc_temp($i_max) $scc_temp($i_resid)
  set i_temp($i_max) $i_temp($i_resid)
}

set file [ open $output_dir/data/to_$mutation.scc_ordered.dat w ] 
puts $file "# Ordered side chain contributions. "
puts $file "# Warning: zeroes may be reflect simulations that failed. "
puts $file "# Residue    Side-chain contribution "
for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
  set line "$resname($i_scc($i_resid)) $resid($i_scc($i_resid))" 
  set line "$line [ format %10.3f $scc_final($i_scc($i_resid)) ]"
  puts $file $line
}
close $file

# Write warning for residues for which simulations failed

for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
  if { [ info exists failed_nat($i_resid) ] |
       [ info exists failed_mut($i_resid) ] } { 
    set warning 1
    break
  } 
}
for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
  if { [ info exists failed_nat($i_resid) ] } { 
    puts " WARNING: Failed reading data of [ nat_dir $i_resid ]"
  } 
  if { [ info exists failed_mut($i_resid) ] } { 
    puts " WARNING: Failed reading data of [ mut_dir $i_resid ]"
  } 
}
if { [ info exists warning ] } {
  puts " > These warnings mean that some output files could not "
  puts " > be read and the output graphs may be incomplete. "
  puts " > The file that is used for the present analysis "
  puts " > is \"temperatures.dat\", which should have been generated"
  puts " > by the atd_temperatures.tcl script for each simulation. "
  puts " > Check the directories of the warnings above for this "
  puts " > files for aditional information. "
}

puts " ---------------------------------------------- "
puts " Normal termination of ATD_SIDECHAINS script. "
puts " ---------------------------------------------- "













