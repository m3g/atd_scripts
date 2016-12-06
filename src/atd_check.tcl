#!/usr/bin/tclsh
#
# atd_check.tcl
#
# How to run it:   ./atd_check.tcl atd_script.inp [native|ALA|GLY...]
#
# Where "atd_script.inp" the input file.
#
# This script will check the status of ATD simulations that are running.
#
# L. Martinez, Oct 30, 2009.
#

source ATD_SCRIPTS_DIR/atd_procs.tcl

puts " ---------------------------------------------- "
puts " ATD_CHECK output. "
puts " ---------------------------------------------- "

array set arg [ check_args $argv "check" ]
                                                     
source ATD_SCRIPTS_DIR/atd_common.tcl

# Run the compute_temperature program for every output file


set log " ---------------------------------------------- "
puts " ---------------------------------------------- "
if { $native } {
  puts " Checking the running status of native simulations "
  set n_error 0
  set n_finished 0
  set n_running 0
  for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
    progress $i_resid $n_resid
    if { [ file isfile [ nat_dir $i_resid ]/namd.log ] } {
      set error [ string first "ERROR" [ exec cat [ nat_dir $i_resid ]/namd.log ] ]
      if { $error != -1  } { 
        incr n_error
        set log "$log\n  Simulation of $resname($i_resid)$resid($i_resid) ended with an error. " 
      } else {
        set finished [ string first "finished" [ exec cat [ nat_dir $i_resid ]/namd.log ] ]
        if { $finished != -1 } { 
          incr n_finished 
        } else {
          set log "$log\n Simulation of $resname($i_resid)$resid($i_resid) is running. "
          incr n_running
        }
      }
    }
  }

} else {
  puts " Checking the running status of to_$mutation simulations "
  set n_error 0
  set n_finished 0
  set n_running 0
  for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
    progress $i_resid $n_resid
    if { [ file isfile [ mut_dir $i_resid ]/namd.log ] } {
      set error [ string first "ERROR" [ exec cat [ mut_dir $i_resid ]/namd.log ] ]
      if { $error != -1  } { 
        incr n_error
        set log "$log\n Simulation of $resname($i_resid)$resid($i_resid) ended with an error. " 
      } else {
        set finished [ string first "finished" [ exec cat [ mut_dir $i_resid ]/namd.log ] ]
        if { $finished != -1 } { 
          incr n_finished 
        } else {
          set log "$log\n Simulation of $resname($i_resid)$resid($i_resid) is running. "
          incr n_running
        }
      }
    }
  }

}

puts $log
puts " ---------------------------------------------- "
puts " Summary: "
puts " Total number of simulations: $n_resid "
puts " Simulations finished: $n_finished "
puts " Simulations ended with errors: $n_error "
puts " Simulations running: $n_running "


puts " ---------------------------------------------- "
puts " Normal termination of ATD_CHECK script. "
puts " ---------------------------------------------- "

