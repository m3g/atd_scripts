#!/usr/bin/tclsh
#
# atd_clean.tcl
#
# How to run it:   ./atd_clean.tcl atd_script.inp [native|ALA|GLY...]
#
# Where "atd_script.inp" the input file.
#
# This script will remove all files created by and ATD run. 
# be careful! It removes the following files from the "output"
# directory of each simulations:
#
# velocities, namd.log, atd.coor, atd.vel, atd.xsc
#
# It is generally used only to clean the preparation to restart
# a simulation that was broken for some reason.
#
# L. Martinez, Aug 28, 2009.
#

source ATD_SCRIPTS_DIR/atd_procs.tcl

puts " ---------------------------------------------- "
puts " ATD_CLEAN output. "
puts " ---------------------------------------------- "

array set arg [ check_args $argv "clean" ]
                                                     
source ATD_SCRIPTS_DIR/atd_common.tcl

# Run the compute_temperature program for every output file

if { $native } {

  puts " Cleaning simulation output files from native simulations "
  for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
    progress $i_resid $n_resid
    exec rm -f [ nat_dir $i_resid ]/velocities
    exec rm -f [ nat_dir $i_resid ]/namd.log
    exec rm -f [ nat_dir $i_resid ]/atd.coor
    exec rm -f [ nat_dir $i_resid ]/atd.vel
    exec rm -f [ nat_dir $i_resid ]/atd.xsc
  }

} else {

  puts " Cleaning simulation output files from to_$mutation simulations "
  for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
    progress $i_resid $n_resid
    exec rm -f [ mut_dir $i_resid ]/velocities
    exec rm -f [ mut_dir $i_resid ]/namd.log
    exec rm -f [ mut_dir $i_resid ]/atd.coor
    exec rm -f [ mut_dir $i_resid ]/atd.vel
    exec rm -f [ mut_dir $i_resid ]/atd.xsc
  }

}

puts " ---------------------------------------------- "
puts " Normal termination of ATD_CLEAN script. "
puts " ---------------------------------------------- "

