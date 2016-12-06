!
! compute_temperature: This program reads the PSF file of a simulation
!                      and the correspondent VELOCITY DCD file, from
!                      which it computes the average temperature, along
!                      the simulation, of each residue in the structure.
!
! L. Martinez, Aug 27, 2009.
!

! Static variables
 
implicit none
integer :: dummyi, i, j, k, ires, nres, natoms, firstatom, &
           nframes, last_res_num, resnum, iatom, narg, status,&
           firstresidue
real :: dummyr, vmod, conv_kelvin, convert, k_tot, temp_tot,&
        final_kinetic_energy
character(len=200) :: record, psffile, velocities, output
character(len=4) :: dummyc, resname, last_res_name, segment, seg_temp

! Allocatable arrays

real, allocatable :: vx(:), vy(:), vz(:), ave_temp(:), fin_temp(:), mass(:),&
                     ave_k_per_res(:), fin_k_per_res(:), ave_kinetic(:), fin_kinetic(:)
integer, allocatable :: natres(:)  

! Open input file and read parameters

narg = iargc()
if(narg /= 3) then
  write(*,*) ' Run with: ./compute_temperature psffile.psf velocity.dcd SEGN '
  stop
end if   

call getarg(1,psffile)
call getarg(2,velocities)
call getarg(3,record)
read(record,*) segment
call getarg(4,output)

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

allocate( mass(natoms), ave_kinetic(natoms), fin_kinetic(natoms),&
          vx(natoms), vy(natoms), vz(natoms),& 
          natres(nres), ave_temp(nres), fin_temp(nres),&
          ave_k_per_res(nres), fin_k_per_res(nres) )  

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

! Reseting the vector that will contain the kinetic energy per atom 

do i = 1, natoms
  ave_kinetic(i) = 0.
end do

! Reading the velocities

final_kinetic_energy = 0.
do i = 1, nframes
  read(10) (dummyr,j=1,firstatom-1),(vx(j),j=1,natoms)
  read(10) (dummyr,j=1,firstatom-1),(vy(j),j=1,natoms)
  read(10) (dummyr,j=1,firstatom-1),(vz(j),j=1,natoms)
  do j = 1, natoms
    vmod = vx(j)**2 + vy(j)**2 + vz(j)**2
    ave_kinetic(j) = ave_kinetic(j) + 0.5 * mass(j) * vmod  
    if ( i == nframes ) then
      final_kinetic_energy = final_kinetic_energy + 0.5 * mass(j) * vmod
      fin_kinetic(j) = 0.5 * mass(j) * vmod
    end if
  end do
end do
close(10)

! Converting kinetic energy to J / mol averaging per frame

convert = (2045.482706)**2 / 1000.
do i = 1, natoms
  ave_kinetic(i) = convert * ave_kinetic(i) / real(nframes)
  fin_kinetic(i) = convert * fin_kinetic(i)
end do

! Computing aveage kinetic energy and temperature per residue
! and the total kinetic energy and temperature

conv_kelvin = 2. / 3. / 8.3145
iatom = 0
k_tot = 0.
do i = 1, nres
  ave_k_per_res(i) = 0.
  fin_k_per_res(i) = 0.
  do j = 1, natres(i)
    iatom = iatom + 1
    ave_k_per_res(i) = ave_k_per_res(i) + ave_kinetic(iatom)
    fin_k_per_res(i) = fin_k_per_res(i) + fin_kinetic(iatom)
    k_tot = k_tot + ave_kinetic(iatom)
  end do
  ave_k_per_res(i) = ave_k_per_res(i) / real(natres(i))
  fin_k_per_res(i) = fin_k_per_res(i) / real(natres(i))
  ave_temp(i) = conv_kelvin * ave_k_per_res(i)
  fin_temp(i) = conv_kelvin * fin_k_per_res(i)
end do
k_tot = k_tot / real(natoms)

temp_tot = conv_kelvin * k_tot

write(*,"( a, a )") '# PSF file: ', psffile(1:len_trim(psffile))
write(*,"( a, a )") '# Velocity file: ', velocities(1:len_trim(velocities))
write(*,"( a, a )") '# Segment: ', segment
write(*,"( a, f12.6 )") '# Average temperature: ', temp_tot
write(*,"( a, f12.6 )") '# Final temperature: ',&
     final_kinetic_energy * convert * conv_kelvin / real(natoms)
write(*,"( a )") '# Temperature (K) and '
write(*,"( a )") '# kinetic energies (kcal/mol) per residue, per atom: '
write(*,"( a )") '#    RESIDUE    AVERAGE_TEMP   AVERAGE_KINET    FINAL_TEMP   FINAL_KINET '
do i = 1, nres
  write(*,*) i+firstresidue-1, ave_temp(i), ave_k_per_res(i) / ( 4.182 * 1000. ),&
                               fin_temp(i), fin_k_per_res(i) / ( 4.182 * 1000. )
end do
          
end



