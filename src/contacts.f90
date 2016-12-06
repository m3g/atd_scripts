!
! program contacs
!
! Computes the contact map of some segment in some PDB file,
! and outputs the data such that it will be read by the atd_map.tcl
! script to write a xmgrace file with the contact and thermal diffusion
! maps.
!
! Run with:  contacts pdb_file.pdb SEGN
!
! where pdb_file.pdb is the pdb file to be considered and SEGN is the
! segment name.
!
! L. Martinez, Sep 3, 2009.
!

program contacts

implicit none
integer :: i, j, ires, jres, natoms, nres, reslnum, resnum, narg, status,&
           iatom, jatom, color, firstres
real :: dist 

integer, allocatable :: natres(:), firstatom(:)
real, allocatable :: x(:), y(:), z(:), dij(:,:)

character(len=4) ::  reslname, resname, segment
character(len=200) :: pdbfile, record

narg = iargc()
if ( narg /= 2 ) then
  write(*,*) ' ERROR: Run with ./contacts pdb_file.pdb SEGN '
  stop
end if 

call getarg(1,pdbfile)
call getarg(2,record)
read(record,*) segment 

open(10,file=pdbfile,action='read',iostat=status)
if ( status /= 0 ) then
  write(*,*) ' ERROR: Could not open pdb file. '
  stop
end if

! Openning the pdb file and reading the number of atoms and residues
! of the segment of interest

natoms = 0
nres = 0
reslname = "LAST"
reslnum = 0
firstres = 0
do 
  read(10,"( a200 )",iostat=status ) record
  if ( status /= 0 ) exit
  if ( ( record(1:4) == "ATOM" .or. &
         record(1:6) == "HETATM" ) .and. &
         record(73:76) == segment ) then
    natoms = natoms + 1
    read(record(23:26),*) resnum
    read(record(18:21),*) resname
    if ( firstres == 0 ) firstres = resnum
    if ( resname /= reslname .or. &
         resnum /= reslnum ) then
      nres = nres + 1
      reslnum = resnum
      reslname = resname
    end if
  end if
end do

if ( natoms == 0 ) then
  write(*,*) ' ERROR: Found no atoms of selected segment. '
  stop
end if
if ( nres == 0 ) then
  write(*,*) ' ERROR: Found no residues in selected segment. '
  stop
end if

! Allocate arrays

allocate( natres(nres), firstatom(nres), dij(nres,nres), &
          x(natoms), y(natoms), z(natoms) )

! Now will actually read the coordinates

rewind(10)
natoms = 0
nres = 0
reslname = "LAST"
reslnum = 0
do 
  read(10,"( a200 )",iostat=status ) record
  if ( status /= 0 ) exit
  if ( ( record(1:4) == "ATOM" .or. &
         record(1:6) == "HETATM" ) .and. &
         record(73:76) == segment ) then
    natoms = natoms + 1
    read(record(31:38),*) x(natoms)
    read(record(39:46),*) y(natoms)
    read(record(47:54),*) z(natoms)
    read(record(23:26),*) resnum
    read(record(18:21),*) resname
    if ( resname /= reslname .or. &
         resnum /= reslnum ) then
      nres = nres + 1
      natres(nres) = 1
      firstatom(nres) = natoms
      reslnum = resnum
      reslname = resname
    else 
      natres(nres) = natres(nres) + 1
    end if
  end if
end do
close(10)

! Computing distances and setting the residue-residue distance matrix

firstres = firstres - 1
do ires = firstres + 1, firstres + nres
  write(*,"( 3(tr2,i6) )") ires, ires, 50
end do
do ires = 1, nres - 1
  do jres = ires + 1, nres
    iatom = firstatom(ires)
    dij(ires,jres) = dist(iatom,firstatom(jres),x,y,z)
    do i = 1, natres(ires)
      jatom = firstatom(jres)
      do j = 1, natres(jres)
        dij(ires,jres) = amin1( dij(ires,jres), dist(iatom,jatom,x,y,z) )
        jatom = firstatom(jres) + j
      end do
      iatom = firstatom(ires) + i
    end do
    color = min( 76 , int(dij(ires,jres)*26./8. + 50.) )
    write(*,"( 3(tr2,i6) )") firstres + ires, firstres + jres, color
    write(*,"( 3(tr2,i6) )") firstres + jres, firstres + ires, color
  end do
end do

end

! Compute the distance

function dist( i, j, x, y, z )

implicit none
integer :: i, j
real :: x(*), y(*), z(*), dist

dist = sqrt ((x(i) - x(j))**2 + &
             (y(i) - y(j))**2 + &
             (z(i) - z(j))**2)    

return
end


