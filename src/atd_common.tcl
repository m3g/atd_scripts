#!/usr/bin/tclsh
#
# atd_common.tcl
#
# Contains common code for all atd_*.tcl scripts
#
# L. Martinez, Aug 26, 2009.
#
set input_file $arg(1)
set system $arg(2)

puts " Input file name: $arg(1)"
set native 0
set mutation 0
if { $arg(2) == "native" } {
  puts " Will deal with native simulation. "
  set native 1
} else {
  puts " Will deal with $arg(2) mutant simulations. "
  set mutation $arg(2) 
}

# Current working directory

set current_dir [ exec pwd ]

#
# Reading information from the input file
#

puts " Opening input file: $input_file"
set file [ open $input_file r ] 
set input [ read $file ]
close $file
set input [ split $input "\n" ]

set n_par_files 0
foreach line $input {

  array set words [ parse_line $line " " ]
  if { $words(1) == "psfgen_script" } {
    set psfgen_script_name $words(2)
    if { [ file isfile $psfgen_script_name ] == 0 } {
      puts " ERROR: Could not find psfgen script file: $psfgen_script_name"
      exit
    } else {
      puts " Found psfgen script file: $psfgen_script_name"
    }
  }
  if { $words(1) == "parameters" } {
    incr n_par_files
    set par_files($n_par_files) $words(2)
    if { [ file isfile $par_files($n_par_files) ] == 0 } {
      puts " ERROR: Could not find parameter file: $par_files($n_par_files)"
      exit
    } else {
      puts " Found parameter file: $par_files($n_par_files)"
    }
  }
  if { $words(1) == "psfgen" } {
    set psfgen $words(2)
    if { [ file isfile $psfgen ] == 0 } {
      puts " ERROR: Could not find psfgen executable: $psfgen"
      exit
    } else {
      puts " Found psfgen executable. "
    }
  }
  if { $words(1) == "namd2" } {
    set namd2 $words(2)
    if { [ file isfile $namd2 ] == 0 } {
      puts " ERROR: Could not find namd2 executable: $namd2"
      exit
    } else {
      puts " Found namd2 executable. "
    }
  }
  if { $words(1) == "namdinput" } {
    set namdinput $words(2)
    if { [ file isfile $namdinput ] == 0 } {
      puts " ERROR: Could not find file: $namdinput"
      exit
    } else {
      puts " Found standard namd input file: $namdinput "
    }
  }
  if { $words(1) == "number_of_procs" } {
    set number_of_procs $words(2)
    if { $number_of_procs < 1 |
         [ string is integer -strict $number_of_procs ] != 1 } { 
      puts " ERROR: Number of processors must be at least one. "
      exit
    } else {
      puts " Will use $number_of_procs processors. "
    }
  }
}

#
# Opening the psfgen script file and reading it
#

puts " ---------------------------------------------- "
puts " Opening psfgen script: $psfgen_script_name "
set file [ open $psfgen_script_name r ]
set psfgen_script [ read $file ]
close $file
set psfgen_script [ split $psfgen_script "\n" ]

foreach line $psfgen_script { 
  array set words [ parse_line $line " " ]
  array set vars [ parse_line $line "=" ]
  if { $words(1) == "segment" } {  
    set segment $words(2)
    puts " Found segment: $segment "
  }
  if { $words(1) == "#MUTATE" } {  
    puts " Residues of $segment are set to be mutated. "
    set mutate_segment $segment
  }
  if { $vars(1) == "equilibrated_pdb" } {
    set pdb_file_name $vars(2) 
    if { [ string range $pdb_file_name 0 0 ] != "/" } {
      set path_to_psfgen_script "$current_dir/[ get_path $psfgen_script_name ]"
      set pdb_file_name "$path_to_psfgen_script/$pdb_file_name"
    }
    puts " Base PDB file of the system: $pdb_file_name "
  }
}

#
# Opening the PDB file for the first time and checking the
# number of residues, their names and the correctness of the
# segment names
#

puts " ---------------------------------------------- "
puts " Opening the PDB file. "
if { [ file isfile $pdb_file_name ] == 0 } {
  puts "ERROR: Could not find PDB file: $pdb_file_name "
  exit
}

set file [ open $pdb_file_name r ]
set pdb_file [ read $file ]
close $file
set pdb_file [ split $pdb_file "\n" ]

set n_resid 0
foreach line $pdb_file {
  if { [ string range $line 0 3 ] == "ATOM" | 
       [ string range $line 0 5 ] == "HETATM" } {
    set segment [ string trim [ string range $line 72 75 ] ]
    if { $segment == $mutate_segment } { 
      if { $n_resid == 0 } {
        puts " Found segment to be mutated, $segment, in the PDB file."
        set resname(1) [ string trim [ string range $line 17 19 ] ]
        set resid(1) [ string trim [ string range $line 22 25 ] ]
        incr n_resid
      } else {
        set thisresidue [ string trim [ string range $line 22 25 ] ]
        if { $thisresidue != $resid($n_resid) } {
          incr n_resid
          set resname($n_resid) [ string trim [ string range $line 17 19 ] ]
          set resid($n_resid) $thisresidue
        }
      }
    }
  }
}
puts " Found $n_resid residues on segment $mutate_segment "
if { $n_resid < 1 } {
  puts " ERROR: Segment $mutate_segment contains no residues."  
  exit
}
puts " First residue: $resid(1), last residue: $resid($n_resid) "

# Setting default output directories

set output_dir "$current_dir/output"
set mutants_dir "$output_dir/to_$mutation"
set native_dir "$output_dir/native"

