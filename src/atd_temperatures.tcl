#!/usr/bin/tclsh
#
# atd_temperatures.tcl
#
# How to run it:   ./atd_temperatures.tcl atd_script.inp [ native/GLY/... ]
#
# Where "atd_script.inp" the input file.
#
# and native/GLY/ALA/... is the set of simulations for which the temperatures
# will be computed (native, mutated to GLY, to ALA, etc... )
#
# This script writes "temperatures.dat" files in the directory of 
# every simulation. These files can be ploted to check how the protein
# responds to the heating of the specific residue. Also, they are used
# as input files for the other analysis scripts.
#
# L. Martinez, Sep 1, 2009.
#

source ATD_SCRIPTS_DIR/atd_procs.tcl

puts " ---------------------------------------------- "
puts " ATD_TEMPERATURES output. "
puts " ---------------------------------------------- "

array set arg [ check_args $argv "temperatures" ]

source ATD_SCRIPTS_DIR/atd_common.tcl

puts " ---------------------------------------------- "

if { $native } {
  puts " Computing temperatures for the native simulations. "
} else { 
  puts " Computing temperatures for the $mutation mutant simulations. "
}

# Run the compute_temperature program for every output file

puts " Analysing the output velocity files... "

for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {

  progress $i_resid $n_resid

# Computing average and final temperatures from velocity files

# Native simulations
  
  if { $native } {
    if { [ check_run "native" $i_resid ] } {
      exec ATD_SCRIPTS_DIR/compute_temperature \
               $output_dir/PSFGEN/native.ready.psf \
               [ nat_dir $i_resid ]/velocities \
               $mutate_segment > [ nat_dir $i_resid ]/temperatures.dat
    } else {
      set failed($i_resid) 1
      continue
    }

# Mutant simulations

  } else {
  
    if { [ check_run "mutant" $i_resid ] } {
      exec ATD_SCRIPTS_DIR/compute_temperature \
               [ mut_dir $i_resid ]/mutant.ready.psf \
               [ mut_dir $i_resid ]/velocities \
               $mutate_segment > [ mut_dir $i_resid ]/temperatures.dat
    } else {
      set failed($i_resid) 1
      continue
    }

  }
}

# Write warning for residues for which simulations failed

for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
  if { [ info exists failed($i_resid) ] } { 
    set warning 1
    break
  } 
}
for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
  if { [ info exists failed($i_resid) ] } { 
    puts " WARNING: Failed reading data of $resname($i_resid)$resid($i_resid)"
  } 
}
if { [ info exists warning ] } {
  puts " > These warnings mean that some output files could not "
  puts " > be read and the output data may be incomplete. "
  puts " > The files that are checked for the analysis of each "
  puts " > simulation are: \"velocities\", \"namd.log\" and "
  puts " > \"temperatures.dat\", which should have been generated"
  puts " > by this script. Check the directories of the warnings " 
  puts " > above for this files for aditional information. "
}

puts " ---------------------------------------------- "
puts " Normal termination of ATD_TEMPERATURES script. "
puts " ---------------------------------------------- "













