#!/usr/bin/tclsh
#
# atd_total.tcl
#
# How to run it:   ./atd_total.tcl atd_script.inp [native/GLY/ALA/...]
#
# Where "atd_script.inp" the input file.
#
# and native/GLY/ALA/... is the set of simulations to be considered
#
# This script analyses ATD simulations that were run with
# the atd_run.tcl script and for which the temperatures where
# already computed with the atd_temperatures.tcl script. 
# Relevant output files will be put at 
# the output/data directory
#
# This script will compute the side chain contributions 
# for the mutant selected
#
# L. Martinez, Dec 6, 2016
#

source ATD_SCRIPTS_DIR/bin/atd_procs.tcl

puts " ---------------------------------------------- "
puts " ATD_TOTAL output. "
puts " ---------------------------------------------- "

array set arg [ check_args $argv "total" ]

source ATD_SCRIPTS_DIR/bin/atd_common.tcl

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

  if { $native } {

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

    if { [ info exists nat_final_temp($i_resid) ] == 0 } {
      set nat_final_temp($i_resid) 0.
      set nat_average_temp($i_resid) 0.
      set failed_nat($i_resid) 1
    }

    set scc_average($i_resid) $nat_average_temp($i_resid)
    set scc_final($i_resid) $nat_final_temp($i_resid)
    if { [ info exists failed_nat($i_resid) } { 
      set scc_average($i_resid) 0.
      set scc_final($i_resid) 0.
      continue 
    }

  } else {
  
    # Mutant data

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

    if { [ info exists mut_final_temp($i_resid) ] == 0 } {
      set mut_final_temp($i_resid) 0.
      set mut_average_temp($i_resid) 0.
      set failed_mut($i_resid) 1
    }
    if { [ info exists failed_mut($i_resid) ] } { 
      set scc_average($i_resid) 0.
      set scc_final($i_resid) 0.
      continue 
    }

    set scc_average($i_resid) \
    [ expr $nat_average_temp($i_resid) - $mut_average_temp($i_resid) ]
    set scc_final($i_resid) \
    [ expr $nat_final_temp($i_resid) - $mut_final_temp($i_resid) ]

  }

  if { $scc_average($i_resid) > $max_diff_average } { set max_diff_average $scc_average($i_resid) }
  if { $scc_average($i_resid) < $min_diff_average } { set min_diff_average $scc_average($i_resid) }
  if { $scc_final($i_resid) > $max_diff_final } { set max_diff_final $scc_final($i_resid) }
  if { $scc_final($i_resid) < $min_diff_final } { set min_diff_final $scc_final($i_resid) }

}

#
# Writing the data to files
#

puts " Writing final data files in $output_dir/data"

if { $native } {
  set name "native"
} else {
  set name $mutation
}
set data_average [ open $output_dir/data/total_$name.average.dat w ]
set data_final [ open $output_dir/data/total_$name.final.dat w ]

puts $data_average "# Data of average structure heating
# Residue_Heated  Average_native_temp "
puts $data_final "# Data of final structure heating
# Residue_Heated  Final_native_temp "

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

set file [ open $output_dir/data/total_$name.final_ordered.dat w ] 
puts $file "# Ordered thermal diffusions. "
puts $file "# Warning: zeroes may be reflect simulations that failed. "
puts $file "# Residue    Final_protein_tempererature"
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
puts " Normal termination of ATD_TOTAL script. "
puts " ---------------------------------------------- "













