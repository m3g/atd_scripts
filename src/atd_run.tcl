#!/usr/bin/tclsh
#
# atd_run.tcl
#
# How to run it:   ./atd_run.tcl atd_script.inp
#
# Where "atd_run.inp" the input file.
#
# This script runs ATD simulations for some structure and for all
# residues in the structure mutated to ALA on GLY, as indicated in the
# accompanying PSFGEN script (an example for this script is provided). 
#
# It is absolutely mandatory that an equilibrated system (usually a protein) 
# is used as the default PDB file, because no minimization or equilibration
# will be performed from here.
#
# The script will take care of analysing the data and producing the 
# relevant data for building Thermal Diffusion Maps, Residue-by-residue
# contributions and side-chain contributions.
#
# L. Martinez, Aug 26, 2009.
#

source ATD_SCRIPTS_DIR/bin/atd_procs.tcl

puts " ---------------------------------------------- "
puts " ATD_SCRIPT output. "
puts " ---------------------------------------------- "

array set arg [ check_args $argv "run" ]
                                                     
source ATD_SCRIPTS_DIR/bin/atd_common.tcl

# Checking for previous output files, will not overwrite if present

check_files

# Running the simulations!

#
# Create the scripts that will run the simulations
#

# Number of residues per processor 

puts " ---------------------------------------------- "
puts " Creating the script that runs all simulations. "

set n_resids_per_proc [ expr $n_resid / $number_of_procs ]
set remaning_resids [ expr $n_resid - $n_resids_per_proc * $number_of_procs ]

set procs ""
for { set i 1 } { $i <= $number_of_procs } { incr i } {
  set proc_group($i) ""
  set procs "$procs $i"
}
if { $native } {
  set i_resid 0
  set i_proc 0
  while { $i_resid < $n_resid } {
    incr i_proc
    incr i_resid
    set proc_group($i_proc) "$proc_group($i_proc) [ nat_dir $i_resid ]"
    if { $i_proc == $number_of_procs } { set i_proc 0 }
  }
} else {
  set i_resid 0
  set i_proc 0
  while { $i_resid < $n_resid } {
    incr i_proc
    incr i_resid
    set proc_group($i_proc) "$proc_group($i_proc) [ mut_dir $i_resid ]"
    if { $i_proc == $number_of_procs } { set i_proc 0 }
  }
}

if { $native } { 
  set run_script "run_sims_native.sh" 
} else {
  set run_script "run_sims_to_$mutation.sh"
}

set file [ open $output_dir/$run_script w ]
puts $file "#!/bin/bash
cd $current_dir
"
for { set i_proc 1 } { $i_proc <= $number_of_procs } { incr i_proc } {
puts $file "
for dir in $proc_group($i_proc); do
  cd \$dir
  $namd2 input.namd >& namd.log 
  cd $current_dir
done &
"
}
close $file

#
# Executing the script!
#

puts " ---------------------------------------------- "
puts " Running all simulations. "

exec chmod +x $output_dir/$run_script
exec $output_dir/$run_script & 

puts " Your simulations should be running now. "

puts " ---------------------------------------------- "
puts " Normal termination of ATD script. "
puts " ---------------------------------------------- "





