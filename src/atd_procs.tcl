#!/usr/bin/tclsh
#
# atd_procs.tcl
#
# Contains common procedures for all atd_*.tcl scripts
#
# L. Martinez, Aug 26, 2009.
#

# Check if the command line arguments were provided correctly 

proc check_args { argv script } {
  array set words [ parse_line $argv " " ]
  set error 0
  if { $words(2) == "########" } { set error 1 }      
  if { [ file isfile $words(1) ] != 1 } {
    puts " ERROR: Could not find input file. "
    set error 1
  }
  if { $words(2) != "native" } { 
    set aas "ALA ARG ASN ASP CYS GLU GLN GLY HIS ILE \
             LEU LYS MET PHE PRO SER THR TRP TYR VAL"
    if { [ string first $words(2) $aas ] == -1 } {
      set error 1
    }
  }
  if { $error } { 
    puts " Run this script with: ./atd_$script.tcl atd_script.inp \[native/GLY/ALA...\]"
    exit 
  }
  set arg(1) $words(1)
  set arg(2) $words(2)
  for { set i 3 } { $i <= 4 } { incr i } {
    if { [ info exists words($i) ] == 1 } {
      set arg($i) $words($i)
    }
  }
  array get arg
}

# Separate a line in words(1) and words(2)

proc parse_line { line char } {
  set line [ split $line $char ]
  set i 0
  set words(1) "########"
  set words(2) "########"
  foreach word $line { 
    if { $word > " " & $word != $char } { incr i; set words($i) $word }
  }
  array get words 
}

# Check if files from previous runs are not present
 
proc check_files { } {
  global native mutation n_resid
  if { $native } {
    for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
      set file [ nat_dir $i_resid ]/velocities 
      if { [ file isfile $file ] } {
        puts " ERROR: Found previous run files in [ nat_dir $i_resid ] "
        puts "        Run atd_clean.tcl first if you want to start over. "
        exit
      }
    }
  } else {        
    for { set i_resid 1 } { $i_resid <= $n_resid } { incr i_resid } {
      set file [ mut_dir $i_resid ]/velocities 
      if { [ file isfile $file ] } {
        puts " ERROR: Found previous run files in [ mut_dir $i_resid ] "
        puts "        Run atd_clean.tcl first if you want to start over. "
        exit
      }
    }
  }       
}

# Check if a specific run was successful

proc check_run { type i_resid } {
  set run_ok 1
  if { $type == "native" } { set dir [ nat_dir $i_resid ] }
  if { $type == "mutant" } { set dir [ mut_dir $i_resid ] }
  if { [ file isfile $dir/namd.log ] != 1 |
       [ file isfile $dir/velocities ] != 1 } {
    set run_ok 0
  }
  set file [ open $dir/namd.log r ]
  set namdlog [ read $file ]
  close $file
  if { [ string first "ERROR" $namdlog ] != -1 } {
    set run_ok 0
  }     
  return $run_ok
}

# Returns the directory containing a specific native simulation

proc nat_dir { i_resid } {
  global output_dir resid resname mutation
  set nat_dir $output_dir/native/$resid($i_resid)_$resname($i_resid)
  return $nat_dir
}

# Returns the directory containing a specific mutant simulation

proc mut_dir { i_resid } {
  global output_dir resid resname mutation
  set mut_dir $output_dir/to_$mutation/$resid($i_resid)_$resname($i_resid)_to_$mutation
  return $mut_dir
}

# Set color for charged residues in output graphs

proc color { resname } {
  set color 0
  if { $resname == "ARG" } { set color 10 }
  if { $resname == "LYS" } { set color  2 }
  if { $resname == "GLU" } { set color 12 }
  if { $resname == "ASP" } { set color  3 }
  return $color
}

# Return the path of a file given the name with the whole path

proc get_path { file } {
  set last_bar [ string last "/" $file ]
  if { $last_bar >= 0 } {
    set path [ string range $file 0 [ expr $last_bar - 1 ] ]
  } else {
    set path "./"
  }
  return $path 
}

# Write the progress of a long computation

proc progress { i n } {
  set progress [ expr 100. * $i / $n ]
  if { $i == 1 } { puts -nonewline " Progress:        " ; flush stdout }
  puts -nonewline [ format "%5s%5.2f%1s" "\b\b\b\b\b\b" "$progress" "%" ] ; flush stdout 
  if { $i == $n } { puts " Done. " ; flush stdout }
}





