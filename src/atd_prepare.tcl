#!/usr/bin/tclsh
#
# atd_prepare.tcl
#
# How to run it:   ./atd_prepare.tcl atd_script.inp
#
# Where "atd_script.inp" the input file.
#
# This script prepares ATD simulations for some structure and for all
# residues in the structure mutated to ALA on GLY, as indicated in the
# accompanying PSFGEN script (an example for this script is provided). 
#
# It is absolutely mandatory that an equilibrated system (usually a protein) 
# is used as the default PDB file, because no minimization or equilibration
# will be performed from here.
#
# Following this script, the script atd_run.tcl should be used to run
# the simulations.
#
# L. Martinez, Aug 26, 2009.
#

source ATD_SCRIPTS_DIR/bin/atd_procs.tcl

puts " ---------------------------------------------- "
puts " ATD_PREPARE output. "
puts " ---------------------------------------------- "

array set arg [ check_args $argv "prepare" ]

source ATD_SCRIPTS_DIR/bin/atd_common.tcl

# Checking for previous output files, will not overwrite if present

check_files

# Creating output directories

exec mkdir -p $output_dir
exec mkdir -p $output_dir/PSFGEN
if { $native } { 
  exec mkdir -p $native_dir 
} else { 
  exec mkdir -p $mutants_dir
}

# Estimating the ammount of disk space that will be required

set size [ exec wc -l $pdb_file_name ]
array set words [ parse_line $size " " ]
set size [ expr ( $words(1) / 4159. ) * 8.1 * $n_resid / 1000. ]
puts " Estimated storage per simulation set: [ format %3.0f $size ] GB "

#
# For each residue in the segment that will be mutated, create
# a directory in the output_dir for the native and for the
# mutant simulation  
#

puts " Creating directories for each simulation ... "
for { set i 1 } { $i <= $n_resid } { incr i } {
  progress $i $n_resid
  if { $native } { 
    exec mkdir -p [ nat_dir $i ] 
  } else {
    exec mkdir -p [ mut_dir $i ] 
  }
}

#
# Native structure input files
#

# For the native structure, run psfgen to build the files ready to run

if { $native } {

  puts " ---------------------------------------------- "
  puts " Creating psf file for the native simulations "

  set psfgen_file_name $output_dir/PSFGEN/native.psfgen
  set file [ open $psfgen_file_name  w ]
  foreach line $psfgen_script {
    set line [ string map \
        [ list "DEFAULT_PSFGEN_DIR" . ] $line ]
    set line [ string map [ list "DEFAULT_OUTPUT_NAME" native.ready ] $line ]
    set line [ string map [ list "PSFGEN_EXECUTABLE" $psfgen ] $line ]
    if { [ string first "equilibrated_pdb=" $line ] != -1 } {
      puts $file "equilibrated_pdb=$pdb_file_name"
    } else { 
      puts $file $line
    }
  }
  close $file
  
# Run psfgen to build the native psf and pdb files
  
  catch { 
    exec chmod +x $psfgen_file_name
    exec cp $pdb_file_name $output_dir/PSFGEN/
    cd $output_dir/PSFGEN 
    exec ./native.psfgen
    cd $current_dir
  } psfgen_output
  
  set error [ string first "ERROR" $psfgen_output ]
  if { $error != -1 } {
    puts $psfgen_output
    puts " ERROR: Found error in psfgen execution. Check above. "
    exit
  }
  puts " Succesfully created file: $psfgen_file_name "
  set psf [ exec ls [ glob $output_dir/PSFGEN/*ready.psf ] ]
  puts " Created psf file: $psf " 
  set pdb [ exec ls [ glob $output_dir/PSFGEN/*ready.pdb ] ]
  puts " Created pdb file: $pdb " 
  
#
# Now, for each residue, create a PDB file in which the
# b-factor of that residue is different from zero,
# so that temperature coupling will be applyed to that
# residue only 
#
  
  puts " ---------------------------------------------- "
  puts " Creating PDB files with appropriate b-factors "
  puts " that define which residue will be heated... "
  
  set file [ open $pdb r ] 
  set pdb_file [ read $file ]
  close $file
  set pdb_file [ split $pdb_file "\n" ]
  
  for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
  
    progress $i_resid $n_resid
  
    set output_pdb \
    [ open [ nat_dir $i_resid ]/heat.pdb w ]
    foreach line $pdb_file {
      set segment [ string trim [ string range $line 72 75 ] ]
      if { [ string range $line 0 3 ] == "ATOM" | 
           [ string range $line 0 5 ] == "HETATM" } {
        if { $segment == $mutate_segment } {
          set this_residue [ string trim [ string range $line 22 25 ] ]
          if { $this_residue == $resid($i_resid) } {
            puts $output_pdb \
                 "[ string range $line 0 53 ]  0.00 99.99[ string range $line 67 80 ]"
          } else {
            puts $output_pdb \
                 "[ string range $line 0 53 ]  0.00  0.00[ string range $line 67 80 ]"
          }
        } else {
          puts $output_pdb \
               "[ string range $line 0 53 ]  0.00  0.00[ string range $line 67 80 ]"
        }
      } else {
        puts $output_pdb $line
      }
    }
  }

#
# Mutant structure input files
#

} else {

  puts " ---------------------------------------------- "
  puts " Creating psf files for the mutant simulations "
  
  set psfgen_file_name $output_dir/PSFGEN/to_$mutation.psfgen
  for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
  
    progress $i_resid $n_resid
  
    set file [ open $psfgen_file_name w ]
    foreach line $psfgen_script {
      set line [ string map \
          [ list "DEFAULT_PSFGEN_DIR" . ] $line ]
      set line \
      [ string map [ list "DEFAULT_OUTPUT_NAME" mutant.ready ] $line ]
      set line [ string map [ list "PSFGEN_EXECUTABLE" $psfgen ] $line ]
      if { [ string first "equilibrated_pdb=" $line ] != -1 } {
        puts $file "equilibrated_pdb=$pdb_file_name"
      } elseif { [ string range $line 0 6 ] == "#MUTATE" } {
        puts $file "  mutate $resid($i_resid) $mutation"
      } else {
        puts $file $line
      }
    }
    close $file
  
# Run psfgen to build the mutant pdb and psf files for each mutation

    catch { 
      exec chmod +x $psfgen_file_name
      exec cp $pdb_file_name $output_dir/PSFGEN/
      cd $output_dir/PSFGEN 
      exec ./to_$mutation.psfgen
      exec mv mutant.ready.psf [ mut_dir $i_resid ]
      exec mv mutant.ready.pdb [ mut_dir $i_resid ]
      cd $current_dir
      exec rm -f $psfgen_file_name 
    } psfgen_output
  
    set error [ string first "ERROR" $psfgen_output ]
    if { $error != -1 } {
      puts $psfgen_output
      puts " ERROR: Found error in psfgen execution. Check above. "
      exit
    }
  }

  puts " ---------------------------------------------- "
  puts " Creating PDB files with appropriate b-factors "
  puts " for mutant simulations. "
  
  for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
  
    progress $i_resid $n_resid
  
    set file [ mut_dir $i_resid ]/mutant.ready.pdb
    set file [ open $file r ] 
    set pdb_file [ read $file ]
    close $file
    set pdb_file [ split $pdb_file "\n" ]
  
    set output_pdb \
    [ open [ mut_dir $i_resid ]/heat.pdb w ]
    foreach line $pdb_file {
      set segment [ string trim [ string range $line 72 75 ] ]
      if { [ string range $line 0 3 ] == "ATOM" | 
           [ string range $line 0 5 ] == "HETATM" } {
        if { $segment == $mutate_segment } {
          set this_residue [ string trim [ string range $line 22 25 ] ]
          if { $this_residue == $resid($i_resid) } {
            puts $output_pdb \
                 "[ string range $line 0 53 ]  0.00 99.99[ string range $line 67 80 ]"
          } else {
            puts $output_pdb \
                 "[ string range $line 0 53 ]  0.00  0.00[ string range $line 67 80 ]"
          }
        } else {
          puts $output_pdb \
               "[ string range $line 0 53 ]  0.00  0.00[ string range $line 67 80 ]"
        }
      } else {
        puts $output_pdb $line
      }
    }
  }
}


# And now, for each residue of the native structure, prepare the corresponding
# namd input file

puts " ---------------------------------------------- "
puts " Creating NAMD input files"

set file [ open $namdinput r ] 
set namdinput [ read $file ]
close $file

set namdinput [ string map [ list "OUTPUT_NAME" "atd" ] $namdinput ]
set namdinput [ string map [ list "DCD_OUTPUT_NAME" "trajectory" ] $namdinput ]
set namdinput [ string map [ list "VEL_DCD_OUTPUT" "velocities" ] $namdinput ]
set namdinput [ string map [ list "HEAT_FILE" "./heat.pdb" ] $namdinput ]
set namdinput [ split $namdinput "\n" ]
set file [ open $output_dir/PSFGEN/input.namd w ]
foreach line $namdinput { 
  if { [ string range $line 0 9 ] == "PARAMETERS" } {
    for { set i 1 } { $i <= $n_par_files } { incr i } {
      puts $file "parameters $par_files($i)"
    }
  } elseif { [ string range $line 0 17 ] == "PERIODIC_CELL_SIZE" } {

  } else {
    puts $file $line
  }
}
close $file

# For native simulations 

if { $native } {
  set nat_namdinput [ string map [ list "STRUCTURE.PSF" $psf ] $namdinput ]
  set nat_namdinput [ string map [ list "STRUCTURE.PDB" $pdb ] $nat_namdinput ]
  set file [ open $output_dir/PSFGEN/nat_input.namd w ]
  foreach line $nat_namdinput { 
    if { [ string range $line 0 9 ] == "PARAMETERS" } {
      for { set i 1 } { $i <= $n_par_files } { incr i } {
        puts $file "parameters $par_files($i)"
      }
    } else {
      puts $file $line
    }
  }
  close $file
  for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
    exec cp $output_dir/PSFGEN/nat_input.namd [ nat_dir $i_resid ]/input.namd
  }

# For mutant simulations

} else {
  set mut_namdinput \
      [ string map \
      [ list "STRUCTURE.PSF" ./mutant.ready.psf ] $namdinput ]
  set mut_namdinput \
      [ string map \
      [ list "STRUCTURE.PDB" ./mutant.ready.pdb ] $mut_namdinput ]
  set file [ open $output_dir/PSFGEN/mut_input.namd w ]
  foreach line $mut_namdinput { 
    if { [ string range $line 0 9 ] == "PARAMETERS" } {
      for { set i 1 } { $i <= $n_par_files } { incr i } {
        puts $file "parameters $par_files($i)"
      }
    } else {
      puts $file $line
    }
  }
  close $file
  for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
    exec cp $output_dir/PSFGEN/mut_input.namd [ mut_dir $i_resid ]/input.namd
  }
}

puts " ---------------------------------------------- "
puts " Normal termination of ATD_PREPARE script. "
puts " ---------------------------------------------- "





