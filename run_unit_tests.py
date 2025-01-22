from vunit import VUnit

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Create libraries
lib = vu.add_library("testbenches")
rrns_arith_lib = vu.add_library("rrns_arith_lib")

# Add the VHDL files
lib.add_source_files("testbenches/rrns_arith_lib_rrns5_tb.vhd")
lib.add_source_files("testbenches/rrns_arith_lib_rrns4_tb.vhd")
rrns_arith_lib.add_source_files("rtl/rrns_arith_lib.vhd")

# Run vunit function
vu.main()
