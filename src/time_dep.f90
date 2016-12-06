!
! time_dep : This programs reads the PSF and Velocity DCD files
!            of a simulation and computes the time-dependent temperatures
!            of al residues. 
! Run with: ./time_dep psffile.psf velocity.dcd SEGN [t_min] [t_max] > output.dat
!
! [t_min] and [t_max] are optional, they are used to build the color scale
! for xmgrace symbols. If they are not set, the scale will be between 0K
! and 300K
!
! L. Martinez, March 26, 2013
!

! Static variables
 
implicit none
integer :: dummyi, i, j, k, ires, nres, natoms, firstatom, &
           nframes, last_res_num, resnum, iatom, narg, status,&
           firstresidue, color
real :: dummyr, vmod, conv_kelvin, convert, t_min, t_max, t_tmp
character(len=200) :: record, psffile, velocities
character(len=4) :: dummyc, resname, last_res_name, segment, seg_temp

! Allocatable arrays

real, allocatable :: vx(:), vy(:), vz(:), temperature(:), t_res(:), mass(:)
integer, allocatable :: natres(:)  

! Open input file and read parameters

narg = iargc()
if(narg < 3) then
  write(*,*) ' Run with: ./time_dep psffile.psf velocity.dcd SEGN [t_min] [t_max]'
  stop
end if   

t_min = 0.
t_max = 300.
call getarg(1,psffile)
call getarg(2,velocities)
call getarg(3,record)
read(record,*) segment
call getarg(4,record)
if ( narg > 3 ) then
  call getarg(4,record)
  read(record,*) t_min
  call getarg(5,record)
  read(record,*) t_max
end if

! Open the psf file and read the residue and atom information

open(10,file=psffile,action='read')
do
  read(10,"( a200 )",iostat=status) record
  if ( status /= 0 ) then
    write(*,*) ' ERROR parsing PSF file. '
    stop
  end if
  if ( record(10:15) == '!NATOM' ) exit
end do
read(record(1:9),*) natoms
firstatom = 0
do
  read(10,"( a200 )") record
  read(record(10:13),*) seg_temp
  firstatom = firstatom + 1
  if ( seg_temp == segment ) exit
end do
backspace(10)
natoms = 0
nres = 0
last_res_name = '#'
last_res_num = 0
firstresidue = 0
do
  read(10,"( a200 )",iostat=status) record
  read(record(10:13),*,iostat=status) seg_temp
  if ( status /= 0 .or. seg_temp /= segment ) exit
  read(record(15:19),*) resnum
  read(record(20:23),*) resname
  if ( firstresidue == 0 ) firstresidue = resnum
  natoms = natoms + 1
  if(resnum.ne.last_res_num.or.&
     resname.ne.last_res_name) then
    last_res_num = resnum
    last_res_name = resname
    nres = nres + 1
  end if
end do

! Allocate arrays

allocate( mass(natoms), vx(natoms), vy(natoms), vz(natoms),& 
          temperature(natoms), natres(nres), t_res(nres) )  

! Now will actually read the relevant data from the psf file

rewind(10)
do
  read(10,"( a200 )",iostat=status) record
  if ( status /= 0 ) then
    write(*,*) ' ERROR parsing PSF file. '
    stop
  end if
  if ( record(10:15) == '!NATOM' ) exit
end do
do
  read(10,"( a200 )") record
  read(record(10:13),*) seg_temp
  if ( seg_temp == segment ) exit
end do
backspace(10)
last_res_name = '#'
last_res_num = 0
ires = 0
iatom = 0
do
  read(10,"( a200 )",iostat=status) record
  read(record(10:13),*,iostat=status) seg_temp
  if ( status /= 0 .or. seg_temp /= segment ) exit
  read(record(15:19),*) resnum
  read(record(20:23),*) resname
  if(resnum.ne.last_res_num.or.&
     resname.ne.last_res_name) then
    last_res_num = resnum
    last_res_name = resname
    ires = ires + 1
    natres(ires) = 1
  else
    natres(ires) = natres(ires) + 1
  end if
  iatom = iatom + 1
  read(record(49:58),*) mass(iatom)
end do
close(10)

! Opening the velocity dcd file and reading the header

open(10,file=velocities,action='read',form='unformatted')
read(10) dummyc, nframes, (dummyi,i=1,8), dummyr, (dummyi,i=1,9)
read(10) dummyi, dummyr
read(10) dummyi

! Convert kinetic energy to J / mol

convert = (2045.482706)**2 / 1000.

! Convert kinetic energy to temperature, in Kelvin

conv_kelvin = 2. / 3. / 8.3145

! Printing the header of the output

write(*,"( a, a )") '# PSF file: ', psffile(1:len_trim(psffile))
write(*,"( a, a )") '# Velocity file: ', velocities(1:len_trim(velocities))
write(*,"( a, a )") '# Segment: ', segment
write(*,"( a, a )") '# FRAME (Temperature of Residue 1) (Temperature of Residue 2) .... '

! Reading the velocities

do i = 1, nframes
  read(10) (dummyr,j=1,firstatom-1),(vx(j),j=1,natoms)
  read(10) (dummyr,j=1,firstatom-1),(vy(j),j=1,natoms)
  read(10) (dummyr,j=1,firstatom-1),(vz(j),j=1,natoms)

  ! Computing the kinetic energy of each atom at this frame

  do j = 1, natoms
    vmod = vx(j)**2 + vy(j)**2 + vz(j)**2
    temperature(j) = conv_kelvin * convert * 0.5 * mass(j) * vmod
  end do

  ! Computing the average (over atoms) temperature of each residue

  iatom = 0
  do j = 1, nres

    ! Computing residue temperature

    t_res(j) = 0.
    do k = 1, natres(j)
      iatom = iatom + 1
      t_res(j) = t_res(j) + temperature(iatom)
    end do
    t_res(j) = t_res(j) / natres(j)

    ! Computing the color of this residue in the 200-226 scale

    t_tmp = amin1( t_max, t_res(j) )
    t_tmp = amax1( t_min, t_tmp )
    color = int(200. + 26.*( t_tmp - t_min ) / ( t_max - t_min )) 
    if ( color > 226 ) then
      write(*,*) t_res(j), t_min, t_max, t_tmp, color
      stop
    end if

    ! Write the temperatures this residue in this frame

    write(*,*) i, j, t_res(j), color

  end do


end do
close(10)

end



