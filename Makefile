# 
# The fortran compiler used to build the ATD scripts to execute
#
# This makefile can be run with:
#
#      make       ( This will build the executable files )
#
# or 
#
#      make clean    ( This will remove the executable files )
#
#
# Requirements: gfortran (or other fortran 90 compiler, change below)
#               tcl 
#
#
# L. Martinez, Aug 31, 2009.
#
# Version 13.086
#
FORTRAN = gfortran
#
FLAGS = -O3 -ffast-math -frecord-marker=4
#
ATD_DIR := $(shell pwd)
BIN := $(ATD_DIR)/bin
#
FILES = $(BIN)/compute_temperature \
        $(BIN)/time_dep \
        $(BIN)/contacts \
        $(BIN)/atd_prepare.tcl \
        $(BIN)/atd_run.tcl \
        $(BIN)/atd_sidechains.tcl \
        $(BIN)/atd_map.tcl \
        $(BIN)/atd_temperatures.tcl \
        $(BIN)/atd_clean.tcl \
        $(BIN)/atd_check.tcl \
        $(BIN)/atd_common.tcl \
        $(BIN)/atd_procs.tcl \
        ./input_example/atd_script.inp

all : $(BIN) $(FILES)
	@echo " -------------------------------------- "
	@echo " ATD scripts are built. "
	@echo " -------------------------------------- "
	@echo " Add the "
	@echo " $(BIN)"
	@echo " to your path. "
	@echo " -------------------------------------- "

$(BIN)/compute_temperature : ./src/compute_temperature.f90
	$(FORTRAN) $(FLAGS) -o $(BIN)/compute_temperature ./src/compute_temperature.f90

$(BIN)/time_dep : ./src/time_dep.f90
	$(FORTRAN) $(FLAGS) -o $(BIN)/time_dep ./src/time_dep.f90

$(BIN)/contacts: ./src/contacts.f90
	$(FORTRAN) $(FLAGS) -o $(BIN)/contacts ./src/contacts.f90

$(BIN)/atd_prepare.tcl : ./src/atd_prepare.tcl
	sed 's!ATD_SCRIPTS_DIR!$(ATD_DIR)!' ./src/atd_prepare.tcl > $(BIN)/atd_prepare.tcl
	chmod +x $(BIN)/atd_prepare.tcl

$(BIN)/atd_run.tcl : ./src/atd_run.tcl
	sed 's!ATD_SCRIPTS_DIR!$(ATD_DIR)!' ./src/atd_run.tcl > $(BIN)/atd_run.tcl
	chmod +x $(BIN)/atd_run.tcl

$(BIN)/atd_sidechains.tcl : ./src/atd_sidechains.tcl
	sed 's!ATD_SCRIPTS_DIR!$(ATD_DIR)!' ./src/atd_sidechains.tcl > $(BIN)/atd_sidechains.tcl
	chmod +x $(BIN)/atd_sidechains.tcl

$(BIN)/atd_map.tcl : ./src/atd_map.tcl
	sed 's!ATD_SCRIPTS_DIR!$(ATD_DIR)!' ./src/atd_map.tcl > $(BIN)/atd_map.tcl
	chmod +x $(BIN)/atd_map.tcl

$(BIN)/atd_temperatures.tcl : ./src/atd_temperatures.tcl
	sed 's!ATD_SCRIPTS_DIR!$(ATD_DIR)!' ./src/atd_temperatures.tcl > $(BIN)/atd_temperatures.tcl
	chmod +x $(BIN)/atd_temperatures.tcl

$(BIN)/atd_clean.tcl : ./src/atd_clean.tcl
	sed 's!ATD_SCRIPTS_DIR!$(ATD_DIR)!' ./src/atd_clean.tcl > $(BIN)/atd_clean.tcl
	chmod +x $(BIN)/atd_clean.tcl

$(BIN)/atd_check.tcl : ./src/atd_check.tcl
	sed 's!ATD_SCRIPTS_DIR!$(ATD_DIR)!' ./src/atd_check.tcl > $(BIN)/atd_check.tcl
	chmod +x $(BIN)/atd_check.tcl

$(BIN)/atd_common.tcl : ./src/atd_common.tcl
	cp ./src/atd_common.tcl $(BIN)/atd_common.tcl

$(BIN)/atd_procs.tcl : ./src/atd_procs.tcl
	cp ./src/atd_procs.tcl $(BIN)/atd_procs.tcl

./input_example/atd_script.inp : ./src/atd_script.inp
	sed 's!ATD_SCRIPTS_DIR!$(ATD_DIR)!' ./src/atd_script.inp > ./input_example/atd_script.inp

$(BIN) : 
	mkdir -p $(BIN)

clean : 
	rm -f $(FILES)

grace : ./xmgrace/Default.agr 
	if [ -f ~/.grace/templates/Default.agr ]; then  mv -f ~/.grace/templates/Default.agr ~/.grace/templates/Default.agr.BAK; fi
	mkdir -p ~/.grace
	mkdir -p ~/.grace/templates
	cp ./xmgrace/Default.agr ~/.grace/templates/




