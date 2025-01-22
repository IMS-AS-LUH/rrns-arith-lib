# RRNS Arith Lib

A VHDL library for using the Redundant Residue Number System (RRNS).
RNS (without the initial R) is an alternative number system that uses residues (remainders) of divisions by different moduli (divisors) to represent numbers.
By adding more moduli without increasing the dynamic range of possible numbers, errors can be detected.

The main library requires full support of VHDL-2008, especially its feature of unconstrained record types.

This library supports:
- Unsigned integer, signed integer, and signed fixed-point numbers
- Conversion from and to conventional binary
- RRNS Addition, Subtraction, and Multiplication
- Integrity checking of the RRNS numbers
- Two moduli sets with one or two redundant moduli


## Use the Library

The VHDL library can be found in the `rtl` directory.
For this example add them to your synthesis project with the library set to `rrns_arith_lib`.
To use the library in VHDL, use the following library use clause:

```vhdl
library rrns_arith_lib;
use rrns_arith_lib.rrns_arith_lib.all;
```

A full usage example can be found in the `examples` folder.

The conventional binary numbers are of the standard IEEE types `unsigned` or `signed` for which the according libraries have to be included:

```vhdl
library ieee;
use ieee.numeric_std.all;
```

To use the signed fixed-point number data types, the standard IEEE library `fixed_pkg` has to be used:

```vhdl
library ieee;
use ieee.fixed_pkg.all;
```

## Generate Documentation

To create the library documentation install [Doxygen](https://doxygen.org).
Then change into the `docs` directory and call:

```bash
doxygen Doxyfile
```

The documentation will then be generated in the same directory.
Read the HTML documentation by opening `html/index.html` in your browser or generate the LaTeX version by calling `make` in the `latex` directory.


## Run Unit Tests

The unit tests are prepared in the `testbenches` directory.
They are run using the Python-based [VUnit](https://vunit.github.io/) test framework.

1. Install VUnit using the guide on the VUnit website.
2. Install a simulator that supports VHDL-2008 and is supported by VUnit.
3. Run the following command on the top level directory of the repository:

```bash
python3 run_unit_tests.py
```

## Citation

Please cite the ISFPGA25 abstract when using this library in scientific works: https://doi.org/10.1145/3706628.3708847


## Bug Reports

Please create an Issue in this repository.


## License

The library is licensed under the CERN-OHL-P v2.
Read the LICENSE file for more information.
