--------------------------------------------------------------------------------
-- Title       : RRNS Arithmetic Library
-- Standard    : VHDL-2008
-- Copyright (c) 2024 Tim Oberschulte
--------------------------------------------------------------------------------
-- Description: Uses redundant RNS numbers for arithmetic and error detection
--------------------------------------------------------------------------------
-- This source describes Open Hardware and is licensed under the CERN-OHL-P v2.
--
-- You may redistribute and modify this source and make products
-- using it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl).
-- This source is distributed WITHOUT ANY EXPRESS OR IMPLIED
-- WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
-- AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-P v2
-- for applicable conditions.
--------------------------------------------------------------------------------


--! Requires the `ieee` standard VHDL library.
library ieee;
--! Logic representation using the standard types `std_ulogic` and `std_ulogic_vector`.
use ieee.std_logic_1164.all;
--! Integer representation using the standard types `unsigned` and `signed`.
use ieee.numeric_std.all;
--! Fixed-point number representation using the standard type `sfixed`
use ieee.fixed_pkg.all;

/*! @brief The RRNS Arith Lib library package
 * 
 *  This package provides functions to use the Redundant Residue Number System (RRNS) with VHDL.
 *  **VHDL-2008** is required! For synthesis or simulation VHDL-2008 or later must be selected.
 *  
 *  All functions are synthesizeable for use in hardware.
 *  Two moduli sets are available for use called R4 and R5.
 *  They use *information* moduli to form the usable dynamic number range and *redundant* moduli to add redundancy for error detection.
 *  
 *  | Residue Number | Modulus           | Residue Length / bit  | R4          | R5          |
 *  |----------------|-------------------|-----------------------|-------------|-------------|
 *  | 1              | 2<sup>n-1</sup>-1 | n-1                   | information | information |
 *  | 2              | 2<sup>n</sup>-1   | n                     | information | information |
 *  | 3              | 2<sup>n</sup>     | n                     | information | information |
 *  | 4              | 2<sup>n</sup>+1   | n+1                   |             | redundant   |
 *  | 5              | 2<sup>n+1</sup>-1 | n+1                   | redundant   | redundant   |
 *  
 *  The redundancy in RRNS basically works by defining a legitimate and an illegitimate range for the numbers.
 *  A bit error in one of the residues results in the number moving from the legitimate to the illegitimate range.
 *  This is shown in the picture below:
 *  
 *  \image html rrns_ranges.png "Visualization of the legitimate and illegitimate range of an RRNS' dynamic range and the movement of a value X to the illegitimate range by addition of an error E." width=500
 *  \image latex rrns_ranges.png "Visualization of the legitimate and illegitimate range of an RRNS' dynamic range and the movement of a value X to the illegitimate range by addition of an error E." width=6cm
 *  
 *  For signed numbers the negative numbers move to the back of the dynamic range as shown in the following picture:
 *  
 *  \anchor img_negative_numbers
 *  \image html rrns_ranges_signed.png "Visualization of the legitimate and illegitimate range of a signed RRNS number with 3 information moduli and 2 redundant moduli." width=500
 *  \image latex rrns_ranges_signed.png "Visualization of the legitimate and illegitimate range of a signed RRNS number with 3 information moduli and 2 redundant moduli." width=6cm
 *  
 *  A synthesizeable usage example depicting the use of the converter functions, arithmetic, and fault detection for RRNS R4 is shown below:
 *  
 *  \include rrns4_example.vhd
 *  
 */
package rrns_arith_lib is

    ----------------------------------------------------------------------------
    -- Type definitions
    ----------------------------------------------------------------------------

    --! @brief RRNS R5 unsigned integer data type
    type rrns5_unsigned is record
        r1      : unsigned; -- Length: n-1
        r2      : unsigned; -- Length: n
        r3      : unsigned; -- Length: n
        r4      : unsigned; -- Length: n+1
        r5      : unsigned; -- Length: n+1
    end record;

    --! @brief RRNS R5 signed integer data type
    type rrns5_signed is record
        r1      : unsigned;
        r2      : unsigned;
        r3      : unsigned;
        r4      : unsigned;
        r5      : unsigned;
    end record;

    --! @brief RRNS R5 signed fixed-point data type
    --! 
    --! Only supports non-negative comma positions for now
    type rrns5_sfixed is record
        number  : rrns5_signed;
        comma   : natural;
    end record;

    --! @brief RRNS R4 unsigned integer data type
    type rrns4_unsigned is record
        r1      : unsigned; -- Length: n-1
        r2      : unsigned; -- Length: n
        r3      : unsigned; -- Length: n
        r5      : unsigned; -- Length: n+1
    end record;

    --! @brief RRNS R4 signed integer data type
    type rrns4_signed is record
        r1      : unsigned;
        r2      : unsigned;
        r3      : unsigned;
        r5      : unsigned;
    end record;

    --! @brief RRNS R4 signed fixed-point data type
    --! 
    --! Only supports non-negative comma positions for now
    type rrns4_sfixed is record
        number  : rrns4_signed;
        comma   : natural;
    end record;

    --! @brief Helper type for residue lengths
    type rrns_lengths_t is array (1 to 5) of natural;


    /*! @brief Calculate the lengths for the five residues for a given moduli set parameter
     *  @public
     *  
     *  @param   n   The moduli set parameter
     *  @return      Array of the residue lengths
     *  Calculates the residue lengths for the used moduli sets R4 and R5.
     *  In the R4 set residue 4 is not used.
     */
    function rrns_residue_lengths(n : natural) return rrns_lengths_t;

    ----------------------------------------------------------------------------
    -- Public Library Functions for RRNS R5 moduli set
    ----------------------------------------------------------------------------

    /*! @brief Convert to RRNS R5 unsigned integer from an `ieee.numeric_std` unsigned binary integer
     *  @public
     *  
     *  @param   arg The signal or variable to convert from
     *  @param   n   The moduli set parameter
     *  @return      An RRNS R5 unsigned integer number
     *  
     *  Forward-converter based on <i>A Pure Combinational Logic Gate Based Forward Converter for New Five Moduli Set RNS</i> by Debabrat Boruah and Monjul Saikia.
     *  https://ieeexplore.ieee.org/abstract/document/7306698
     */
    function to_rrns5_unsigned(arg : unsigned; n : natural) return rrns5_unsigned;

    /*! @brief Convert to RRNS R5 unsigned integer from a VHDL natural
     *  @public
     *  
     *  @param   arg The signal or variable to convert from
     *  @param   n   The moduli set parameter
     *  @return      An RRNS R5 unsigned integer number
     */
    function to_rrns5_unsigned(arg : natural; n : natural) return rrns5_unsigned;

    /*! @brief Decode an ieee.std_logic_1164.std_ulogic_vector to an RRNS R5 unsigned integer
     *  @public
     *  
     *  @param   arg The signal or variable to decode from
     *  @param   n   The moduli set parameter
     *  @return      An RRNS R5 unsigned integer number
     *  
     *  This function only copies the residues from the std_ulogic_vector, no conversion is conducted!
     *  
     *  The residues must be encoded downwards in the vector:
     *          
     *      vector(upper downto lower) := residue5(upper downto lower) & ... & residue1(upper downto lower)
     *      
     *  The lengths of the residues can be determined using rrns_residue_lengths().
     *  
     *  Encoding to a `std_ulogic_vector` is found in the function to_sulv().
     */
    function to_rrns5_unsigned(arg : std_ulogic_vector; n : natural) return rrns5_unsigned;

    /*! @brief Convert to RRNS R5 signed integer from an IEEE.numeric_std signed binary integer
     *  @public
     *  
     *  @param   arg The signal or variable to convert from
     *  @param   n   The moduli set parameter
     *  @return      An RRNS R5 signed integer number
     *  
     *  Uses the forward-converter from to_rrns5_unsigned().
     *  
     *  If the number is negative, it will be shifted to the back of the RNS range as shown in the \ref img_negative_numbers "picture" above.
     */
    function to_rrns5_signed(arg : signed  ; n : natural) return rrns5_signed;

    /*! @brief Decode an ieee.std_logic_1164.std_ulogic_vector to an RRNS R5 signed integer
     *  @public
     *  
     *  @param   arg The signal or variable to decode from
     *  @param   n   The moduli set parameter
     *  @return      An RRNS R5 signed integer number
     *  
     *  This function only copies the residues from the std_ulogic_vector, no conversion is conducted!
     *  
     *  The residues must be encoded downwards in the vector:
     *          
     *      vector(upper downto lower) := residue5(upper downto lower) & ... & residue1(upper downto lower)
     *      
     *  The lengths of the residues can be determined using rrns_residue_lengths().
     */
    function to_rrns5_signed(arg : std_ulogic_vector  ; n : natural) return rrns5_signed;

    /*! @brief Convert to RRNS R5 signed fixed-point number from an `ieee.fixed_pkg sfixed`
     *  @public
     *  
     *  @param   arg The signal or variable to convert from
     *  @param   n   The moduli set parameter
     *  @return      An RRNS R5 signed fixed-point number
     *  
     *  Uses the conversion from to_rrns5_signed().
     *  Stores the comma position as set in the `sfixed`.
     */
    function to_rrns5_sfixed(arg : sfixed  ; n : natural) return rrns5_sfixed;

    /*! @brief Decode an ieee.std_logic_1164.std_ulogic_vector to an RRNS R5 signed fixed-point number
     *  @public
     *  
     *  @param   arg    The signal or variable to decode from
     *  @param   n      The moduli set parameter
     *  @param   comma  The comma position of the fixed-point number
     *  @return         An RRNS R5 signed fixed-point number
     *  
     *  This function only copies the residues from the std_ulogic_vector, no conversion is conducted!
     *  
     *  The residues must be encoded downwards in the vector:
     *          
     *      vector(upper downto lower) := residue5(upper downto lower) & ... & residue1(upper downto lower)
     *      
     *  The lengths of the residues can be determined using rrns_residue_lengths().
     */
    function to_rrns5_sfixed(arg : std_ulogic_vector; n : natural; comma : natural) return rrns5_sfixed;

    /*! @brief Convert an RRNS R5 unsigned number to an `ieee.numeric_std` unsigned
     * 
     *  @param arg  RRNS number to convert
     *  @param size Length of the output number
     *  @return     The binary representation of the RRNS number
     *  
     *  The reverse-conversion is conducted only using the information moduli 1, 2, and 3.
     *  The result will lie in the range of rrns5_redundant_range_u().
     *  
     *  Reverse-converter based on <i>New residue to binary converters for the moduli set {2<sup>k</sup>, 2<sup>k</sup>-1, 2<sup>k-1</sup>-1}<i> by P. V. Ananda Mohan.
     *  https://ieeexplore.ieee.org/document/4766524
     */
    function to_unsigned(arg : rrns5_unsigned; size : natural) return unsigned;

    /*! @brief Convert an RRNS R5 signed number to an `ieee.numeric_std` signed
     * 
     *  @param arg  RRNS number to convert
     *  @param size Length of the output number
     *  @return     The binary representation of the RRNS number
     *  
     *  The reverse-conversion is conducted only using the information moduli 1, 2, and 3.
     *  The result will lie in the range of -rrns5_redundant_range_u()/2 to rrns5_redundant_range_u()/2 - 1.
     *  
     *  Reverse-converter based on <i>New residue to binary converters for the moduli set {2<sup>k</sup>, 2<sup>k</sup>-1, 2<sup>k-1</sup>-1}<i> by P. V. Ananda Mohan.
     *  https://ieeexplore.ieee.org/document/4766524
     */
    function to_signed(arg : rrns5_signed; size : natural) return signed;

    /*! @brief Convert an RRNS R5 signed fixed-point number to an `ieee.fixed_pkg` sfixed
     * 
     *  @param arg      RRNS number to convert
     *  @param higher   Upper limit of the sfixed output
     *  @param lower    Lower limit of the sfixed output
     *  @return         The binary representation of the RRNS number
     *  
     *  The reverse-conversion is conducted only using the information moduli 1, 2, and 3.
     *  The result will lie in the range of -rrns5_redundant_range_u()/2 to rrns5_redundant_range_u()/2 - 1 and scaled with the position of the comma.
     *  
     *  Reverse-converter based on <i>New residue to binary converters for the moduli set {2<sup>k</sup>, 2<sup>k</sup>-1, 2<sup>k-1</sup>-1}<i> by P. V. Ananda Mohan.
     *  https://ieeexplore.ieee.org/document/4766524
     */
    function to_sfixed(arg : rrns5_sfixed; higher, lower : integer) return sfixed;

    /*! @brief Checks integrity of a reverse-converted RRNS R5 unsigned
     *  
     *  @param r   An RRNS R5 unsigned integer number
     *  @param num The reverse-converted binary number to check with
     *  @return    Logical '1' if the number is erroneous, else a logical '0'
     */
    function rrns_is_erroneus(r : rrns5_unsigned; num : unsigned) return std_ulogic;

    /*! @brief Checks integrity of a reverse-converted RRNS R5 signed
     *  
     *  @param r   An RRNS R5 signed integer number
     *  @param num The reverse-converted binary number to check with
     *  @return    Logical '1' if the number is erroneous, else a logical '0'
     */
    function rrns_is_erroneus(r : rrns5_signed; num : signed) return std_ulogic;

    /*! @brief Checks integrity of a reverse-converted RRNS R5 fixed-point number
     *  
     *  @param r   An RRNS R5 signed fixed-point number
     *  @param num The reverse-converted binary number to check with
     *  @return    Logical '1' if the number is erroneous, else a logical '0'
     */    
    function rrns_is_erroneus(r : rrns5_sfixed; num : sfixed) return std_ulogic;

    /*! @brief Add two RRNS R5 unsigned integers
     * 
     *  @param l left operand
     *  @param r right operand
     *  @return  The sum of the two operands
     */
    function "+" (l, r : rrns5_unsigned) return rrns5_unsigned;

    /*! @brief Subtract two RRNS R5 unsigned integers
     * 
     *  @param l left operand (minuend)
     *  @param r right operand (subtrahend)
     *  @return  The difference of the two operands
     */
    function "-" (l, r : rrns5_unsigned) return rrns5_unsigned;

    /*! @brief Multiply two RRNS R5 unsigned integers
     * 
     *  @param l left operand
     *  @param r right operand
     *  @return  The product of the two operands
     */
    function "*" (l, r : rrns5_unsigned) return rrns5_unsigned;

    /*! @brief Add two RRNS R5 signed integers
     * 
     *  @param l left operand
     *  @param r right operand
     *  @return  The sum of the two operands
     */
    function "+" (l, r : rrns5_signed) return rrns5_signed;

    /*! @brief Subtract two RRNS R5 signed integers
     * 
     *  @param l left operand (minuend)
     *  @param r right operand (subtrahend)
     *  @return  The difference of the two operands
     */
    function "-" (l, r : rrns5_signed) return rrns5_signed;

    /*! @brief Multiply two RRNS R5 signed integers
     * 
     *  @param l left operand
     *  @param r right operand
     *  @return  The product of the two operands
     */
    function "*" (l, r : rrns5_signed) return rrns5_signed;

    /*! @brief Add two RRNS R5 signed fixed-point numbers
     * 
     *  @param l left operand
     *  @param r right operand
     *  @return  The sum of the two operands
     *  
     *  Note: The comma positions of the operands must be the same
     */
    function "+" (l, r : rrns5_sfixed) return rrns5_sfixed;

    /*! @brief Subtract two RRNS R5 signed fixed-point numbers
     * 
     *  @param l left operand (minuend)
     *  @param r right operand (subtrahend)
     *  @return  The difference of the two operands
     *  
     *  Note: The comma positions of the operands must be the same
     */
    function "-" (l, r : rrns5_sfixed) return rrns5_sfixed;

    /*! @brief Multiply two RRNS R5 signed fixed-point numbers
     * 
     *  @param l left operand
     *  @param r right operand
     *  @return  The product of the two operands
     *  
     *  Note: The comma position of the product is the added comma position of the operands
     */
    function "*" (l, r : rrns5_sfixed) return rrns5_sfixed;

    /*! @brief Get a string representation of an RRNS number
     *  @public
     *  
     *  @param   r   The RRNS number to convert
     *  @return      String representation of the RRNS number
     */
    function to_string(r : rrns5_unsigned) return string;

    /*! @brief Get a string representation of an RRNS number
     *  @public
     *  
     *  @param   r   The RRNS number to convert
     *  @return      String representation of the RRNS number
     */
    function to_string(r : rrns5_signed) return string;

    /*! @brief Get a string representation of an RRNS number
     *  @public
     *  
     *  @param   r   The RRNS number to convert
     *  @return      String representation of the RRNS number
     */
    function to_string(r : rrns5_sfixed) return string;

    /*! @brief Encode an RRNS R5 unsigned integer into an `ieee.std_logic_1164.std_ulogic_vector`
     *  
     *  @param r   An RRNS R5 unsigned integer
     *  @return    A logic vector with the residues
     *  
     *  Concatenates the residues of the RRNS number:
     *  
     *      vector(upper downto lower) := residue5(upper downto lower) & ... & residue1(upper downto lower)
     */
    function to_sulv(r : rrns5_unsigned) return std_ulogic_vector;

    /*! @brief Encode an RRNS R5 signed integer into an `ieee.std_logic_1164.std_ulogic_vector`
     *  
     *  @param r   An RRNS R5 signed integer
     *  @return    A logic vector with the residues
     *  
     *  Concatenates the residues of the RRNS number:
     *  
     *      vector(upper downto lower) := residue5(upper downto lower) & ... & residue1(upper downto lower)
     */    
    function to_sulv(r : rrns5_signed) return std_ulogic_vector;

    /*! @brief Encode an RRNS R5 signed fixed-point number into an `ieee.std_logic_1164.std_ulogic_vector`
     *  
     *  @param r   An RRNS R5 signed fixed-point number
     *  @return    A logic vector with the residues
     *  
     *  Concatenates the residues of the RRNS number:
     *  
     *      vector(upper downto lower) := residue5(upper downto lower) & ... & residue1(upper downto lower)
     */
    function to_sulv(r : rrns5_sfixed) return std_ulogic_vector;


    ----------------------------------------------------------------------------
    -- Public Library Functions for RRNS R4 moduli set
    ----------------------------------------------------------------------------

    /*! @brief Convert to RRNS R4 unsigned integer from an `ieee.numeric_std` unsigned binary integer
     *  @public
     *  
     *  @param   arg The signal or variable to convert from
     *  @param   n   The moduli set parameter
     *  @return      An RRNS R4 unsigned integer
     *  
     *  Forward-converter based on <i>A Pure Combinational Logic Gate Based Forward Converter for New Five Moduli Set RNS</i> by Debabrat Boruah and Monjul Saikia.
     *  https://ieeexplore.ieee.org/abstract/document/7306698
     */
    function to_rrns4_unsigned(arg : unsigned; n : natural) return rrns4_unsigned;

    /*! @brief Convert to RRNS R4 unsigned integer from a VHDL natural
     *  @public
     *  
     *  @param   arg The signal or variable to convert from
     *  @param   n   The moduli set parameter
     *  @return      An RRNS R4 unsigned integer number
     */
    function to_rrns4_unsigned(arg : natural; n : natural) return rrns4_unsigned;

    /*! @brief Decode an `ieee.std_logic_1164.std_ulogic_vector` to an RRNS R4 unsigned integer
     *  @public
     *  
     *  @param   arg The signal or variable to decode from
     *  @param   n   The moduli set parameter
     *  @return      An RRNS R4 unsigned integer
     *  
     *  This function only copies the residues from the `std_ulogic_vector`, no conversion is conducted!
     *  
     *  The residues must be encoded downwards in the vector:
     *          
     *      vector(upper downto lower) := residue5(upper downto lower) & residue3(upper downto lower) ... & residue1(upper downto lower)
     *      
     *  The lengths of the residues can be determined using rrns_residue_lengths().
     *  
     *  Encoding to a `std_ulogic_vector` is found in the function to_sulv().
     */
    function to_rrns4_unsigned(arg : std_ulogic_vector; n : natural) return rrns4_unsigned;


    /*! @brief Convert to RRNS R4 signed integer from an `ieee.numeric_std` signed binary integer
     *  @public
     *  
     *  @param   arg The signal or variable to convert from
     *  @param   n   The moduli set parameter
     *  @return      An RRNS R4 signed integer
     *  
     *  Uses the forward-converter from to_rrns4_unsigned().
     *  
     *  If the number is negative, it will be shifted to the back of the RNS range as shown in the \ref img_negative_numbers "picture" above.
     */    
    function to_rrns4_signed(arg : signed; n : natural) return rrns4_signed;


    /*! @brief Decode an `ieee.std_logic_1164.std_ulogic_vector` to an RRNS R4 signed integer
     *  @public
     *  
     *  @param   arg The signal or variable to decode from
     *  @param   n   The moduli set parameter
     *  @return      An RRNS R4 signed integer
     *  
     *  This function only copies the residues from the `std_ulogic_vector`, no conversion is conducted!
     *  
     *  The residues must be encoded downwards in the vector:
     *          
     *      vector(upper downto lower) := residue5(upper downto lower) & residue3(upper downto lower) ... & residue1(upper downto lower)
     *      
     *  The lengths of the residues can be determined using rrns_residue_lengths().
     *  
     *  Encoding to a `std_ulogic_vector` is found in the function to_sulv().
     */
    function to_rrns4_signed(arg : std_ulogic_vector; n : natural) return rrns4_signed;


    /*! @brief Convert to RRNS R4 signed fixed-point number from an `ieee.fixed_pkg sfixed`
     *  @public
     *  
     *  @param   arg The signal or variable to convert from
     *  @param   n   The moduli set parameter
     *  @return      An RRNS R4 signed fixed-point number
     *  
     *  Uses the conversion from to_rrns4_signed().
     *  Stores the comma position as set in the `sfixed`.
     */
    function to_rrns4_sfixed(arg : sfixed  ; n : natural) return rrns4_sfixed;


    /*! @brief Decode an `ieee.std_logic_1164.std_ulogic_vector` to an RRNS R4 signed fixed-point number
     *  @public
     *  
     *  @param   arg The signal or variable to decode from
     *  @param   n   The moduli set parameter
     *  @param   comma  The comma position of the fixed-point number
     *  @return      An RRNS R4 signed fixed-point number
     *  
     *  This function only copies the residues from the `std_ulogic_vector`, no conversion is conducted!
     *  
     *  The residues must be encoded downwards in the vector:
     *          
     *      vector(upper downto lower) := residue5(upper downto lower) & residue3(upper downto lower) ... & residue1(upper downto lower)
     *      
     *  The lengths of the residues can be determined using rrns_residue_lengths().
     *  
     *  Encoding to a `std_ulogic_vector` is found in the function to_sulv().
     */
    function to_rrns4_sfixed(arg : std_ulogic_vector; n : natural; comma : natural) return rrns4_sfixed;


    /*! @brief Convert an RRNS R4 unsigned number to an `ieee.numeric_std` unsigned
     * 
     *  @param arg  RRNS number to convert
     *  @param size Length of the output number
     *  @return     The binary representation of the RRNS number
     *  
     *  The reverse-conversion is conducted only using the information moduli 1, 2, and 3.
     *  The result will lie in the range of rrns4_redundant_range_u().
     *  
     *  Reverse-converter based on <i>New residue to binary converters for the moduli set {2<sup>k</sup>, 2<sup>k</sup>-1, 2<sup>k-1</sup>-1}<i> by P. V. Ananda Mohan.
     *  https://ieeexplore.ieee.org/document/4766524
     */
    function to_unsigned(arg : rrns4_unsigned; size : natural) return unsigned;


    /*! @brief Convert an RRNS R4 signed number to an `ieee.numeric_std` signed
     * 
     *  @param arg  RRNS number to convert
     *  @param size Length of the output number
     *  @return     The binary representation of the RRNS number
     *  
     *  The reverse-conversion is conducted only using the information moduli 1, 2, and 3.
     *  The result will lie in the range of -rrns4_redundant_range_u()/2 to rrns4_redundant_range_u()/2 - 1.
     *  
     *  Reverse-converter based on <i>New residue to binary converters for the moduli set {2<sup>k</sup>, 2<sup>k</sup>-1, 2<sup>k-1</sup>-1}<i> by P. V. Ananda Mohan.
     *  https://ieeexplore.ieee.org/document/4766524
     */
    function to_signed(arg : rrns4_signed; size : natural) return signed;


    /*! @brief Convert an RRNS R4 signed fixed-point number to an `ieee.fixed_pkg` sfixed
     * 
     *  @param arg      RRNS number to convert
     *  @param higher   Upper limit of the sfixed output
     *  @param lower    Lower limit of the sfixed output
     *  @return         The binary representation of the RRNS number
     *  
     *  The reverse-conversion is conducted only using the information moduli 1, 2, and 3.
     *  The result will lie in the range of -rrns4_redundant_range_u()/2 to rrns4_redundant_range_u()/2 - 1 and scaled with the position of the comma.
     *  
     *  Reverse-converter based on <i>New residue to binary converters for the moduli set {2<sup>k</sup>, 2<sup>k</sup>-1, 2<sup>k-1</sup>-1}<i> by P. V. Ananda Mohan.
     *  https://ieeexplore.ieee.org/document/4766524
     */
    function to_sfixed(arg : rrns4_sfixed; higher, lower : integer) return sfixed;


    /*! @brief Checks integrity of a reverse-converted RRNS R4 unsigned
     *  
     *  @param r   An RRNS R4 unsigned integer number
     *  @param num The reverse-converted binary number to check with
     *  @return    Logical '1' if the number is erroneous, else a logical '0'
     */
    function rrns_is_erroneus(r : rrns4_unsigned; num : unsigned) return std_ulogic;


    /*! @brief Checks integrity of a reverse-converted RRNS R4 signed
     *  
     *  @param r   An RRNS R4 signed integer number
     *  @param num The reverse-converted binary number to check with
     *  @return    Logical '1' if the number is erroneous, else a logical '0'
     */
    function rrns_is_erroneus(r : rrns4_signed; num : signed) return std_ulogic;


    /*! @brief Checks integrity of a reverse-converted RRNS R4 fixed-point number
     *  
     *  @param r   An RRNS R4 signed fixed-point number
     *  @param num The reverse-converted binary number to check with
     *  @return    Logical '1' if the number is erroneous, else a logical '0'
     */
    function rrns_is_erroneus(r : rrns4_sfixed; num : sfixed) return std_ulogic;


    /*! @brief Add two RRNS R4 unsigned integers
     * 
     *  @param l left operand
     *  @param r right operand
     *  @return  The sum of the two operands
     */
    function "+" (l, r : rrns4_unsigned) return rrns4_unsigned;


    /*! @brief Subtract two RRNS R4 unsigned integers
     * 
     *  @param l left operand (minuend)
     *  @param r right operand (subtrahend)
     *  @return  The difference of the two operands
     */
    function "-" (l, r : rrns4_unsigned) return rrns4_unsigned;


    /*! @brief Multiply two RRNS R4 unsigned integers
     * 
     *  @param l left operand
     *  @param r right operand
     *  @return  The product of the two operands
     */
    function "*" (l, r : rrns4_unsigned) return rrns4_unsigned;


    /*! @brief Add two RRNS R4 signed integers
     * 
     *  @param l left operand
     *  @param r right operand
     *  @return  The sum of the two operands
     */
    function "+" (l, r : rrns4_signed) return rrns4_signed;


    /*! @brief Subtract two RRNS R4 signed integers
     * 
     *  @param l left operand (minuend)
     *  @param r right operand (subtrahend)
     *  @return  The difference of the two operands
     */
    function "-" (l, r : rrns4_signed) return rrns4_signed;


    /*! @brief Multiply two RRNS R4 signed integers
     * 
     *  @param l left operand
     *  @param r right operand
     *  @return  The product of the two operands
     */
    function "*" (l, r : rrns4_signed) return rrns4_signed;


    /*! @brief Add two RRNS R4 signed fixed-point numbers
     * 
     *  @param l left operand
     *  @param r right operand
     *  @return  The sum of the two operands
     */
    function "+" (l, r : rrns4_sfixed) return rrns4_sfixed;


    /*! @brief Subtract two RRNS R4 signed fixed-point numbers
     * 
     *  @param l left operand (minuend)
     *  @param r right operand (subtrahend)
     *  @return  The difference of the two operands
     */
    function "-" (l, r : rrns4_sfixed) return rrns4_sfixed;


    /*! @brief Multiply two RRNS R4 signed fixed-point numbers
     * 
     *  @param l left operand
     *  @param r right operand
     *  @return  The product of the two operands
     */
    function "*" (l, r : rrns4_sfixed) return rrns4_sfixed;


    /*! @brief Get a string representation of an RRNS number
     *  @public
     *  
     *  @param   r   The RRNS number to convert
     *  @return      String representation of the RRNS number
     */
    function to_string(r : rrns4_signed) return string;


    /*! @brief Get a string representation of an RRNS number
     *  @public
     *  
     *  @param   r   The RRNS number to convert
     *  @return      String representation of the RRNS number
     */  
    function to_string(r : rrns4_sfixed) return string;


    /*! @brief Get a string representation of an RRNS number
     *  @public
     *  
     *  @param   r   The RRNS number to convert
     *  @return      String representation of the RRNS number
     */
    function to_string(r : rrns4_unsigned) return string;


    /*! @brief Encode an RRNS R4 unsigned integer into an `ieee.std_logic_1164.std_ulogic_vector`
     *  
     *  @param r   An RRNS R4 unsigned integer
     *  @return    A logic vector with the residues
     *  
     *  Concatenates the residues of the RRNS number:
     *  
     *      vector(upper downto lower) := residue5(upper downto lower) & residue3(upper downto lower) & ... & residue1(upper downto lower)
     */
    function to_sulv(r : rrns4_unsigned) return std_ulogic_vector;


    /*! @brief Encode an RRNS R4 signed integer into an `ieee.std_logic_1164.std_ulogic_vector`
     *  
     *  @param r   An RRNS R4 signed integer
     *  @return    A logic vector with the residues
     *  
     *  Concatenates the residues of the RRNS number:
     *  
     *      vector(upper downto lower) := residue5(upper downto lower) & residue3(upper downto lower) & ... & residue1(upper downto lower)
     */
    function to_sulv(r : rrns4_signed) return std_ulogic_vector;


    /*! @brief Encode an RRNS R4 signed fixed-point number into an `ieee.std_logic_1164.std_ulogic_vector`
     *  
     *  @param r   An RRNS R4 signed fixed-point number
     *  @return    A logic vector with the residues
     *  
     *  Concatenates the residues of the RRNS number:
     *  
     *      vector(upper downto lower) := residue5(upper downto lower) & residue3(upper downto lower) & ... & residue1(upper downto lower)
     */
    function to_sulv(r : rrns4_sfixed) return std_ulogic_vector;


    ----------------------------------------------------------------------------
    -- Helper Functions for RRNS R5 moduli set
    ----------------------------------------------------------------------------

    -- Helpers for RRNS5

    /*! @brief Get the moduli set parameter n from an RRNS R5 unsigned integer
     *  @private
     *  
     *  @param r   An RRNS R5 unsigned integer
     *  @return    Moduli set parameter n
     *  
     *  The moduli set parameter is stored implicitly in the lengths of the residues of the RRNS number.
     */
    function rrns5_modulo_n(r : rrns5_unsigned) return natural;


    /*! @brief Get the moduli set parameter n from an RRNS R5 signed integer
     *  @private
     *  
     *  @param r   An RRNS R5 signed integer
     *  @return    Moduli set parameter n
     *  
     *  The moduli set parameter is stored implicitly in the lengths of the residues of the RRNS number.
     */
    function rrns5_modulo_n(r : rrns5_signed) return natural;


    /*! @brief Get the moduli set parameter n from an RRNS R5 signed fixed-point number
     *  @private
     *  
     *  @param r   An RRNS R5 signed fixed-point number
     *  @return    Moduli set parameter n
     *  
     *  The moduli set parameter is stored implicitly in the lengths of the residues of the RRNS number.
     */
    function rrns5_modulo_n(r : rrns5_sfixed) return natural;


    /*! @brief Get the redundant range of the R5 moduli set for a given rrns5_unsigned type
     *  @public
     *  
     *  @param   r   The signal or variable to get the range for
     *  @return      Range supplied by the redundant residues of the RRNS
     *  
     *  Returns the redundant range of the moduli set R5.
     *  The range `0` to `(return_value - 1)` can be stored in the RRNS type while maintaining error detection capabilities.
     *  The return value is an unsigned as the integer type of VHDL is limited to 2<sup>31</sup>.
     */
    function rrns5_redundant_range_u(r : rrns5_unsigned) return unsigned;


    /*! @brief Get the redundant range of the R5 moduli set for a given moduli set parameter
     *  @public
     *  
     *  @param   n   The moduli set parameter
     *  @return      Range supplied by the redundant residues of the RRNS
     *  Returns the redundant range of the moduli set R5.
     *  The range `0` to `(return_value - 1)` can be stored in the RRNS type while maintaining error detection capabilities.
     *  The return value is an unsigned as the integer type of VHDL is limited to 2<sup>31</sup>.
     */
    function rrns5_redundant_range_u(n : natural) return unsigned;


    /*! @brief Get the length of the R5 redundant range number
     *  @public
     *  
     *  @param   n   The moduli set parameter
     *  @return      Length of the redundant range number
     *  Returns the length of the unsigned which represents the maximum value storable by the redundant residues from rrns5_range_u(natural).
     */
    function rrns5_redundant_range_length(n : natural) return natural;


    /*! @brief Get the full range of the R5 moduli set for a given rrns5_unsigned type
     *  @public
     *  
     *  @param   r   The signal or variable to get the range for
     *  @return      Range supplied by all residues of the RNS
     *  
     *  Returns the full range of the moduli set R5.
     *  The return value is an unsigned as the integer type of VHDL is limited to 2<sup>31</sup>.
     */
    function rrns5_range_u(r : rrns5_unsigned) return unsigned;


    /*! @brief Get the full range of the R5 moduli set for a given moduli set parameter
     *  @public
     *  
     *  @param   n   The moduli set parameter
     *  @return      Range supplied by all residues of the RNS
     *  
     *  Returns the full range of the moduli set R5.
     *  The return value is an unsigned as the integer type of VHDL is limited to 2<sup>31</sup>.
     */
    function rrns5_range_u(n : natural) return unsigned;


    /*! @brief Get the length of the R5 full range number
     *  @public
     *  
     *  @param   n   The moduli set parameter
     *  @return      Length of the full range number
     *  
     *  Returns the length of the unsigned which represents the maximum value storable by all residues from rrns5_range_u(natural).
     */
    function rrns5_range_length(n : natural) return natural;


    /*! @brief Convert the residues to string representation
     *  @private
     *  
     *  @param   r   The unsigned RRNS number to convert
     *  @return      String representation of the RRNS residues
     *  
     *  This function is used in the to_string() functions.
     */
    function rrns_residues_to_string(r : rrns5_unsigned) return string;


    /*! @brief Recast an RRNS R5 unsigned to RRNS R5 signed
     *  @private
     *  
     *  @param i   An RRNS R5 unsigned
     *  @return    The RRNS R5 signed
     *  
     *  Copies the residues from one type to the other.
     *  No conversion is done.
     *  
     *  Do not use this function for conversion purposes!
     */
    function to_rrns5_signed(i : rrns5_unsigned) return rrns5_signed;


    /*! @brief Recast an RRNS R5 signed to RRNS R5 unsigned
     *  @private
     *  
     *  @param i   An RRNS R5 signed
     *  @return    The RRNS R5 unsigned
     *  
     *  Copies the residues from one type to the other.
     *  No conversion is done.
     *  
     *  Do not use this function for conversion purposes!
     */
    function to_rrns5_unsigned(i : rrns5_signed) return rrns5_unsigned;


    ----------------------------------------------------------------------------
    -- Helper Functions for RRNS R4 moduli set
    ----------------------------------------------------------------------------

    /*! @brief Get the moduli set parameter n from an RRNS R4 unsigned integer
     *  @private
     *  
     *  @param r   An RRNS R4 unsigned integer
     *  @return    Moduli set parameter n
     *  
     *  The moduli set parameter is stored implicitly in the lengths of the residues of the RRNS number.
     */
    function rrns4_modulo_n(r : rrns4_unsigned) return natural;


    /*! @brief Get the moduli set parameter n from an RRNS R4 signed integer
     *  @private
     *  
     *  @param r   An RRNS R4 signed integer
     *  @return    Moduli set parameter n
     *  
     *  The moduli set parameter is stored implicitly in the lengths of the residues of the RRNS number.
     */    
    function rrns4_modulo_n(r : rrns4_signed) return natural;


    /*! @brief Get the moduli set parameter n from an RRNS R4 signed fixed-point number
     *  @private
     *  
     *  @param r   An RRNS R4 signed fixed-point number
     *  @return    Moduli set parameter n
     *  
     *  The moduli set parameter is stored implicitly in the lengths of the residues of the RRNS number.
     */
    function rrns4_modulo_n(r : rrns4_sfixed) return natural;


    /*! @brief Get the redundant range of the R4 moduli set for a given rrns5_unsigned type
     *  @public
     *  
     *  @param   r   The signal or variable to get the range for
     *  @return      Range supplied by the redundant residues of the RRNS
     *  
     *  Returns the redundant range of the moduli set R4.
     *  The range `0` to `(return_value - 1)` can be stored in the RRNS type while maintaining error detection capabilities.
     *  The return value is an unsigned as the integer type of VHDL is limited to 2<sup>31</sup>.
     */
    function rrns4_redundant_range_u(r : rrns4_unsigned) return unsigned;


    /*! @brief Get the redundant range of the R4 moduli set for a given moduli set parameter
     *  @public
     *  
     *  @param   n   The moduli set parameter
     *  @return      Range supplied by the redundant residues of the RRNS
     *  Returns the redundant range of the moduli set R5.
     *  The range `0` to `(return_value - 1)` can be stored in the RRNS type while maintaining error detection capabilities.
     *  The return value is an unsigned as the integer type of VHDL is limited to 2<sup>31</sup>.
     */
    function rrns4_redundant_range_u(n : natural) return unsigned;


    /*! @brief Get the length of the R4 redundant range number
     *  @public
     *  
     *  @param   n   The moduli set parameter
     *  @return      Length of the redundant range number
     *  Returns the length of the unsigned which represents the maximum value storable by the redundant residues from rrns4_range_u(natural).
     */
    function rrns4_redundant_range_length(n : natural) return natural;


    /*! @brief Get the full range of the R4 moduli set for a given rrns4_unsigned type
     *  @public
     *  
     *  @param   r   The signal or variable to get the range for
     *  @return      Range supplied by all residues of the RNS
     *  
     *  Returns the full range of the moduli set R4.
     *  The return value is an unsigned as the integer type of VHDL is limited to 2<sup>31</sup>.
     */
    function rrns4_range_u(r : rrns4_unsigned) return unsigned;


    /*! @brief Get the full range of the R4 moduli set for a given moduli set parameter
     *  @public
     *  
     *  @param   n   The moduli set parameter
     *  @return      Range supplied by all residues of the RNS
     *  
     *  Returns the full range of the moduli set R4.
     *  The return value is an unsigned as the integer type of VHDL is limited to 2<sup>31</sup>.
     */
    function rrns4_range_u(n : natural) return unsigned;


    /*! @brief Get the length of the R4 full range number
     *  @public
     *  
     *  @param   n   The moduli set parameter
     *  @return      Length of the full range number
     *  
     *  Returns the length of the unsigned which represents the maximum value storable by all residues from rrns4_range_u(natural).
     */
    function rrns4_range_length(n : natural) return natural;


    /*! @brief Convert the residues to string representation
     *  @public
     *  
     *  @param   r   The unsigned RRNS number to convert
     *  @return      String representation of the RRNS residues
     *  
     *  This function is used in the to_string() functions.
     */
    function rrns_residues_to_string(r : rrns4_unsigned) return string;


    /*! @brief Recast an RRNS R4 unsigned to RRNS R4 signed
     *  @private
     *  
     *  @param i   An RRNS R4 unsigned
     *  @return    The RRNS R4 signed
     *  
     *  Copies the residues from one type to the other.
     *  No conversion is done.
     *  
     *  Do not use this function for conversion purposes!
     */
    function to_rrns4_signed(i : rrns4_unsigned) return rrns4_signed;


    /*! @brief Recast an RRNS R4 signed to RRNS R4 unsigned
     *  @private
     *  
     *  @param i   An RRNS R4 signed
     *  @return    The RRNS R4 unsigned
     *  
     *  Copies the residues from one type to the other.
     *  No conversion is done.
     *  
     *  Do not use this function for conversion purposes!
     */
    function to_rrns4_unsigned(i : rrns4_signed) return rrns4_unsigned;

end package rrns_arith_lib;


package body rrns_arith_lib is

    ----------------------------------------------------------------------------
    -- Function for both moduli sets
    ----------------------------------------------------------------------------

    function rrns_residue_lengths(n : natural) return rrns_lengths_t is
        variable ret : rrns_lengths_t;
    begin
        ret(1) := n-1;
        ret(2) := n;
        ret(3) := n;
        ret(4) := n+1;
        ret(5) := n+1;
        return ret;
    end function;


    ----------------------------------------------------------------------------
    -- Internal functions
    ----------------------------------------------------------------------------

    /*! @brief Addition modulo 2<sup>n</sup>-1
     *  @private
     * 
     *  @param l   Left operand
     *  @param r   Right operand
     *  @return    Sum of left and right modulo 2<sup>n</sup>-1
     *  
     *  n is determined by the length of the operands.
     *  l and r must be of the same length.
     *  
     *  Based on <i>Fast modulo 2<sup>n</sup> - 1 and 2<sup>n</sup> + 1 adder using carry-chain on FPGA</i> by Laurent-Stéphane Didier; Luc Jaulmes.
     *  https://ieeexplore.ieee.org/abstract/document/6810475
     */
    function add_mod2Nm1 (l, r : unsigned) return unsigned is
        constant k     : natural := l'length;
        variable carry : unsigned(k+1 downto 0);
        variable sum   : unsigned(k downto 0);
    begin

        assert l'length = r'length report "Residue lengths do not match" severity failure;

        -- Two consecutive adders where the first creates the carry and the second uses it as carry in
        -- carry := resize(l, k+1) + resize(r, k+1) + 1;
        -- sum := resize(l, k+1) + resize(r, k+1) + carry(k downto k);
        -- return sum(k-1 downto 0);

        -- Parallel adders
        carry := (resize(l, k+1) & '1') + (resize(r, k+1) & '1');
        sum   := resize(l, k+1) + resize(r, k+1);
        if carry(k+1) = '1' then
            return carry(k downto 1);
        else
            return sum(k-1 downto 0);
        end if;

    end function;


    /*! @brief Subtraction modulo 2<sup>n</sup>-1
     *  @private
     * 
     *  @param l   Left operand (minuend)
     *  @param r   Right operand (subtrahend)
     *  @return    Difference of left and right operands modulo 2<sup>n</sup>-1
     *  
     *  n is determined by the length of the operands.
     *  l and r must be of the same length.
     *  
     *  Internally uses add_mod2Nm1() with one inverted input.
     */
    function sub_mod2Nm1 (l, r : unsigned) return unsigned is
    begin
        return add_mod2Nm1(l, not r);
    end function;


    /*! @brief Multiplication modulo 2<sup>n</sup>-1
     *  @private
     * 
     *  @param l   Left operand
     *  @param r   Right operand
     *  @return    Product of left and right operands modulo 2<sup>n</sup>-1
     *  
     *  n is determined by the length of the operands.
     *  l and r must be of the same length.
     *  
     *  Uses normal multiplication and add_mod2Nm1() afterwards.
     *  
     *  Based on <i>Efficient VLSI Implementation of Modulo (2<sup>n</sup> +- 1) Addition and Multiplication</i> by Reto Zimmermann
     *  https://ieeexplore.ieee.org/abstract/document/762841
     */
    function mul_mod2Nm1 (l, r : unsigned) return unsigned is
        constant k     : natural := l'length;
        variable prod  : unsigned(2*k-1 downto 0);
    begin
        prod := l * r; -- Should use the FPGA multiply units
        return add_mod2Nm1(prod(k-1 downto 0), prod(2*k-1 downto k));
    end function;


    /*! @brief Addition modulo 2<sup>n</sup>+1
     *  @private
     * 
     *  @param l   Left operand
     *  @param r   Right operand
     *  @return    Sum of left and right operands modulo 2<sup>n</sup>+1
     *  
     *  n is determined by the length of the operands.
     *  l and r must be of the same length.
     *  
     *  Based on <i>Improved Modulo 2<sup>n</sup>+1 Adder Design</i> by Somayeh Timarchi and Keivan Navi.
     *  https://publications.waset.org/14759/improved-modulo-2n-1-adder-design
     */
    function add_mod2Np1 (l, r : unsigned) return unsigned is
        constant k      : natural := l'length - 1; -- The length is k + 1 as the value "k" has to be stored
        variable sum1   : unsigned(k+1 downto 0); -- Length k+2
        variable sum2   : unsigned(k+1 downto 0);

    begin

        assert l'length = r'length report "Residue lengths do not match" severity failure;

        sum1 := resize(l, sum1'length) + resize(r, sum1'length);
        --sum2 := resize(sum1(k downto 0), sum2'length) + (2**k - 1);
        sum2 := resize(sum1(k downto 0), sum2'length) + (shift_left(to_unsigned(1, sum2'length), k) - 1);

        -- If either carry is 1: select sum2
        if (sum1(k+1) or sum2(k+1)) then
            return sum2(k downto 0);
        else
            return sum1(k downto 0);
        end if;

    end function;


    /*! @brief Subtraction modulo 2<sup>n</sup>+1
     *  @private
     * 
     *  @param l   Left operand (minuend)
     *  @param r   Right operand (subtrahend)
     *  @return    Difference of left and right operands modulo 2<sup>n</sup>+1
     *  
     *  n is determined by the length of the operands.
     *  l and r must be of the same length.
     *  
     *  Internally uses add_mod2Np1().
     */
    function sub_mod2Np1 (l, r : unsigned) return unsigned is
        constant k : natural := l'length - 1;
        variable intermediate : unsigned(k downto 0);
    begin
        intermediate := add_mod2Np1(l, not r);
        return add_mod2Np1(intermediate, to_unsigned(3, l'length)); -- this may be done better, for now we leave it to the synthesizer to optimize it
    end function;


    /*! @brief Mutliplication modulo 2<sup>n</sup>+1
     *  @private
     * 
     *  @param l   Left operand
     *  @param r   Right operand
     *  @return    Product of left and right operands modulo 2<sup>n</sup>+1
     *  
     *  n is determined by the length of the operands.
     *  l and r must be of the same length.
     *  
     *  Internally uses common multiplication and add_mod2Np1().
     */
    function mul_mod2Np1 (l, r : unsigned) return unsigned is
        constant k     : natural := l'length - 1;
        variable prod  : unsigned(2*l'length-1 downto 0);
    begin
        prod := l * r; -- Should use the FPGA multiply units
        return sub_mod2Np1('0' & prod(k-1 downto 0), prod(2*k downto k));
    end function;


    /*! @brief RNS Reverse-Converter using the first three residues
     *  @private
     *  
     *  @param r1  Residue 1 (mod 2<sup>n-1</sup>-1)
     *  @param r2  Residue 2 (mod 2<sup>n</sup>-1)
     *  @param r3  Residue 3 (mod 2<sup>n</sup>)
     *  @return    Binary representation of the RNS number
     *  
     *  Reverse-converter based on <i>New residue to binary converters for the moduli set {2<sup>k</sup>, 2<sup>k</sup>-1, 2<sup>k-1</sup>-1}<i> by P. V. Ananda Mohan.
     *  https://ieeexplore.ieee.org/document/4766524
     */
    function r1r2r3_2bin(r1, r2, r3 : unsigned) return unsigned is
        constant n : natural := r3'length;
        variable a : unsigned(n-1 downto 0);
        variable b : unsigned(n-2 downto 0);
        variable c : unsigned(n-2 downto 0);
        -- Named as in the paper
        constant x1 : r3'subtype := r3; -- mod 2^(n)     (length n)
        constant x2 : r2'subtype := r2; -- mod 2^(n)-1   (length n)
        constant x3 : r1'subtype := r1; -- mod 2^(n-1)-1 (length n-1)
        variable msbs : unsigned(2*n-1 downto 0); -- one larger for carry
        variable msb_summand1 : unsigned(2*n-2 downto 0);
        variable msb_summand2 : unsigned(2*n-2 downto 0);
    begin

        -- a = |x2-x1| mod 2^n-1
        a := sub_mod2Nm1(x2, x1); -- both of length n -> ok

        -- b = |x3-x1| mod 2^(n-1)-1
        -- Problem: x1 is of length n and therefore divided into two parts
        b := sub_mod2Nm1(x3, (n-3 downto 0 => '0') & x1(n-1));
        b := sub_mod2Nm1(b, x1(n-2 downto 0));
        b := b(0) & b(n-2 downto 1); -- Cyclic shift

        -- c = |b-a| mod 2^(n-1)-1
        -- Same problem as above
        c := sub_mod2Nm1(b, (n-3 downto 0 => '0') & a(n-1));
        c := sub_mod2Nm1(c, a(n-2 downto 0));

        -- Add them together to the output
        msb_summand1 := c & '1' & (not c);
        msb_summand2 := (others => '1');
        msb_summand2(n-1 downto 0) := a;

        -- Add them with carry = 1
        msbs := (msb_summand1 & '1') + (msb_summand2 & '1');

        return msbs(msbs'high downto 1) & r3;

    end function;



    ----------------------------------------------------------------------------
    -- RRNS R5
    ----------------------------------------------------------------------------

    function rrns_residues_to_string(r : rrns5_unsigned) return string is
    begin
        return "<" &
            to_string(to_integer(r.r1)) & ", " &
            to_string(to_integer(r.r2)) & ", " &
            to_string(to_integer(r.r3)) & ", " &
            to_string(to_integer(r.r4)) & ", " &
            to_string(to_integer(r.r5)) & ">";
    end function;


    function to_string(r : rrns5_unsigned) return string is
    begin
        return "rrns5_unsigned" & rrns_residues_to_string(r);
    end function;


    function to_string(r : rrns5_signed) return string is
    begin
        return "rrns5_signed" & rrns_residues_to_string(to_rrns5_unsigned(r));
    end function;


    function to_string(r : rrns5_sfixed) return string is
    begin
        return to_string(r.number) & "_Comma=" & to_string(r.comma);
    end function;


    function rrns5_redundant_range_length(n : natural) return natural is
    begin
        return 3*n;
    end function;


    function rrns5_redundant_range_u(r : rrns5_unsigned) return unsigned is
        constant n : natural := rrns5_modulo_n(r);
    begin
        return rrns5_redundant_range_u(n);
    end function;


    function rrns5_redundant_range_u(n : natural) return unsigned is
        variable ret : unsigned(rrns5_redundant_range_length(n)-1 downto 0);
    begin
        ret := shift_left(to_unsigned(1, ret'length), n-1) - to_unsigned(1, ret'length); -- 2**(n-1) - 1
        ret := resize(ret * (shift_left(to_unsigned(1, ret'length), n) - to_unsigned(1, ret'length)), ret'length); -- 2**(n) - 1
        ret := resize(ret * (shift_left(to_unsigned(1, ret'length), n)), ret'length); -- 2**(n)
        return ret;
    end function;


    function rrns5_range_u(r : rrns5_unsigned) return unsigned is
        constant n : natural := rrns5_modulo_n(r);
    begin
        return rrns5_range_u(n);
    end function;


    function rrns5_range_u(n : natural) return unsigned is
        variable ret : unsigned(rrns5_range_length(n)-1 downto 0);
    begin
        ret := shift_left(to_unsigned(1, ret'length), n-1) - to_unsigned(1, ret'length); -- 2**(n-1) - 1
        ret := resize(ret * (shift_left(to_unsigned(1, ret'length), n) - to_unsigned(1, ret'length)), ret'length); -- 2**(n) - 1
        ret := resize(ret * (shift_left(to_unsigned(1, ret'length), n)), ret'length); -- 2**(n)
        ret := resize(ret * (shift_left(to_unsigned(1, ret'length), n) + to_unsigned(1, ret'length)), ret'length); -- 2**(n) + 1
        ret := resize(ret * (shift_left(to_unsigned(1, ret'length), n+1) - to_unsigned(1, ret'length)), ret'length); -- 2**(n+1) - 1
        return ret;
    end function;


    function rrns5_range_length(n : natural) return natural is
    begin
        return 5*n;
    end function;


    function to_rrns5_unsigned(arg: unsigned; n : natural) return rrns5_unsigned is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        constant n_zeros : unsigned(n-1 downto 0) := (others => '0');
        variable b_in : unsigned(rrns5_range_length(n)-1 downto 0);
        variable rrns_out : rrns5_unsigned(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r4(RRNS_LENS(4)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));

        variable k1_0, k1_1, k1_2, k1_3, k1_4, k1_5 : unsigned(n-2 downto 0);
        variable k2_0, k2_1, k2_2, k2_3, k2_4 : unsigned(n-1 downto 0);
        variable k3_0, k3_1, k3_2, k3_3, k3_4 : unsigned(n downto 0);
        variable k2_0_n, k2_1_n, k2_2_n, k2_3_n, k2_4_n : unsigned(n downto 0);

        variable r1_0, r1_1, r1_2, r1_3 : unsigned(n-2 downto 0);
        variable r2_0, r2_1, r2_2: unsigned(n-1 downto 0);
        variable r4_0, r4_1, r4_2: unsigned(n downto 0);
        variable r5_0, r5_1, r5_2: unsigned(n downto 0);

    begin

        assert n >= 6 report "The moduli set paramater n must be equal to or larger than 6" severity error;
        assert n mod 2 = 0 report "The moduli set paramater n must be an even integer" severity error;

        b_in := resize(arg, b_in'length); -- Length 5n

        -- Partition the number into parts of (n-1) bits
        k1_0 := b_in(n-2 downto 0);
        k1_1 := b_in(2*n-3 downto n-1);
        k1_2 := b_in(3*n-4 downto 2*n-2);
        k1_3 := b_in(4*n-5 downto 3*n-3);
        k1_4 := b_in(5*n-6 downto 4*n-4);
        k1_5 := resize(b_in(b_in'high downto 5*n-5), k1_5'length);

        -- Partition the number into parts of n bits
        k2_0 := b_in(n-1 downto 0);
        k2_1 := b_in(2*n-1 downto n);
        k2_2 := b_in(3*n-1 downto 2*n);
        k2_3 := b_in(4*n-1 downto 3*n);
        k2_4 := b_in(5*n-1 downto 4*n);

        -- Partition the number into parts of n+1 bits
        k3_0 := b_in(n downto 0);
        k3_1 := b_in(2*n+1 downto n+1);
        k3_2 := b_in(3*n+2 downto 2*n+2);
        k3_3 := b_in(4*n+3 downto 3*n+3);
        k3_4 := resize(b_in(b_in'high downto 4*n+4), k3_4'length);

        -- Easy residue 3
        rrns_out.r3 := k2_0;

        -- r1 = (k1_0 + k1_1 + k1_2 + k1_3 + k1_4 + k1_5) mod 2^(n-1) - 1:
        -- Adder tree
        r1_0 := add_mod2Nm1(k1_0, k1_1); --A
        r1_1 := add_mod2Nm1(k1_2, k1_3); --B
        r1_2 := add_mod2Nm1(k1_4, k1_5); --C
        r1_3 := add_mod2Nm1(r1_1, r1_2); --B+C

        rrns_out.r1 := add_mod2Nm1(r1_0, r1_3); -- A+B+C


        -- r2 = (k2_0 + k2_1 + k2_2 + k2_3 + k2_4) mod 2^n - 1:
        r2_0 := add_mod2Nm1(k2_0, k2_1); --A
        r2_1 := add_mod2Nm1(k2_2, k2_3); --B
        r2_2 := add_mod2Nm1(r2_1, k2_4); --B + k2_4

        rrns_out.r2 := resize(add_mod2Nm1(r2_0, r2_2), rrns_out.r2'length);


        -- r4 = (k2_0 - k2_1 + k2_2 - k2_3 + k2_4) mod 2^n + 1:
        -- Padded with 0 as the add/sub function require n+1 length
        k2_0_n := '0' & k2_0;
        k2_1_n := '0' & k2_1;
        k2_2_n := '0' & k2_2;
        k2_3_n := '0' & k2_3;
        k2_4_n := '0' & k2_4;

        r4_0 := sub_mod2Np1(k2_0_n, k2_1_n); --A
        r4_1 := sub_mod2Np1(k2_2_n, k2_3_n); --B
        r4_2 := add_mod2Np1(r4_1, k2_4_n); --B + k2_4

        rrns_out.r4 := add_mod2Np1(r4_0, r4_2);

        -- r5 = (k3_0 + k3_1 + k3_2 + k3_3 + k3_4) mod 2^(n+1) - 1:
        r5_0 := add_mod2Nm1(k3_0, k3_1); -- A
        r5_1 := add_mod2Nm1(k3_2, k3_3); -- B
        r5_2 := add_mod2Nm1(r5_1, k3_4); -- B + k3_4

        rrns_out.r5 := add_mod2Nm1(r5_0, r5_2);

        return rrns_out;

    end function;



    function to_rrns5_unsigned (arg : natural; n : natural) return rrns5_unsigned is
        constant num : unsigned(3*n+1 downto 0) := to_unsigned(arg, 3*n+2);
    begin

        assert to_unsigned(arg, rrns5_range_length(n)) < rrns5_redundant_range_u(n)
            report "Number too large for redundant RRNS range. May move to illegitimate range!" severity warning;

        return to_rrns5_unsigned(num, n);

    end function;


    function to_rrns5_unsigned (arg : std_ulogic_vector; n : natural) return rrns5_unsigned is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        variable result : rrns5_unsigned(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r4(RRNS_LENS(4)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
        variable upper : natural;
    begin
        result.r1 := unsigned(arg(RRNS_LENS(1)-1 downto 0));
        upper := RRNS_LENS(1);
        result.r2 := unsigned(arg(upper+RRNS_LENS(2)-1 downto upper));
        upper := upper + RRNS_LENS(2);
        result.r3 := unsigned(arg(upper+RRNS_LENS(3)-1 downto upper));
        upper := upper + RRNS_LENS(3);
        result.r4 := unsigned(arg(upper+RRNS_LENS(4)-1 downto upper));
        upper := upper + RRNS_LENS(4);
        result.r5 := unsigned(arg(upper+RRNS_LENS(5)-1 downto upper));
        return result;
    end function;


    function to_rrns5_signed (arg : signed; n : natural) return rrns5_signed is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        variable rrns_intermediate : rrns5_unsigned(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r4(RRNS_LENS(4)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
        variable rotated : signed(rrns5_range_length(n) downto 0);
    begin

        -- If the number is smaller than 0 we have to shift it to negative
        if arg < 0 then -- Check if the synthesizer is clever and just checks the sign bit
            rotated := resize(signed(rrns5_range_u(n)), rrns5_range_length(n)+1) + arg;

            rrns_intermediate := to_rrns5_unsigned(unsigned(rotated), n); -- Add arg as the number is negative
        else
            rrns_intermediate := to_rrns5_unsigned(unsigned(arg), n);
        end if;

        return to_rrns5_signed(rrns_intermediate);

        -- There is an alternative to this: subtract the constant RRNS number "rrnsRange/2" after converting the abs
        -- This would also protect the conversion process more as it is redundant

    end function;


    function to_rrns5_signed (arg : std_ulogic_vector; n : natural) return rrns5_signed is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        variable result : rrns5_signed(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r4(RRNS_LENS(4)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
        variable upper : natural;
    begin
        result.r1 := unsigned(arg(RRNS_LENS(1)-1 downto 0));
        upper := RRNS_LENS(1);
        result.r2 := unsigned(arg(upper+RRNS_LENS(2)-1 downto upper));
        upper := upper + RRNS_LENS(2);
        result.r3 := unsigned(arg(upper+RRNS_LENS(3)-1 downto upper));
        upper := upper + RRNS_LENS(3);
        result.r4 := unsigned(arg(upper+RRNS_LENS(4)-1 downto upper));
        upper := upper + RRNS_LENS(4);
        result.r5 := unsigned(arg(upper+RRNS_LENS(5)-1 downto upper));
        return result;
    end function;


    function to_rrns5_sfixed (arg : sfixed  ; n : natural) return rrns5_sfixed is
        constant len      : natural := arg'length;
        constant comma    : natural := -arg'low;
        variable shifted  : sfixed(len downto arg'low);

        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        variable result   : rrns5_sfixed(
                number(
                r1(RRNS_LENS(1)-1 downto 0),
                r2(RRNS_LENS(2)-1 downto 0),
                r3(RRNS_LENS(3)-1 downto 0),
                r4(RRNS_LENS(4)-1 downto 0),
                r5(RRNS_LENS(5)-1 downto 0))
            );
    begin

        shifted := shift_left(resize(arg, len, arg'low), comma);

        result.number := to_rrns5_signed(signed(shifted(len-1 downto 0)), n);
        result.comma  := comma;

        return result;

    end function;


    function to_rrns5_sfixed (arg : std_ulogic_vector; n : natural; comma : natural) return rrns5_sfixed is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        variable result   : rrns5_sfixed(
                number(
                r1(RRNS_LENS(1)-1 downto 0),
                r2(RRNS_LENS(2)-1 downto 0),
                r3(RRNS_LENS(3)-1 downto 0),
                r4(RRNS_LENS(4)-1 downto 0),
                r5(RRNS_LENS(5)-1 downto 0))
            );
        variable upper : natural;
    begin
        result.number.r1 := unsigned(arg(RRNS_LENS(1)-1 downto 0));
        upper := RRNS_LENS(1);
        result.number.r2 := unsigned(arg(upper+RRNS_LENS(2)-1 downto upper));
        upper := upper + RRNS_LENS(2);
        result.number.r3 := unsigned(arg(upper+RRNS_LENS(3)-1 downto upper));
        upper := upper + RRNS_LENS(3);
        result.number.r4 := unsigned(arg(upper+RRNS_LENS(4)-1 downto upper));
        upper := upper + RRNS_LENS(4);
        result.number.r5 := unsigned(arg(upper+RRNS_LENS(5)-1 downto upper));

        result.comma := comma;

        return result;
    end function;


    function "+" (l, r : rrns5_unsigned) return rrns5_unsigned is
        variable tmp3 : l.r3'subtype;
        variable ret  : l'subtype;
    begin
        tmp3 := l.r3 + r.r3;

        ret.r1 := add_mod2Nm1(l.r1, r.r1);
        ret.r2 := add_mod2Nm1(l.r2, r.r2);
        ret.r3 := tmp3(ret.r3'range);
        ret.r4 := add_mod2Np1(l.r4, r.r4);
        ret.r5 := add_mod2Nm1(l.r5, r.r5);
        return ret;
    end function "+";


    function "+" (l, r : rrns5_signed) return rrns5_signed is
    begin
        return to_rrns5_signed(to_rrns5_unsigned(l) + to_rrns5_unsigned(r));
    end function;


    function "+" (l, r : rrns5_sfixed) return rrns5_sfixed is
        variable result : l'subtype;
    begin

        assert l.comma = r.comma report "The integer and fractional parts must match for addition in RRNS." severity failure;
        
        result.number := l.number + r.number;
        result.comma  := l.comma;

        return result;
    end function;


    function "-" (l, r : rrns5_unsigned) return rrns5_unsigned is
        constant n    : natural := l.r3'length;
        variable tmp3 : unsigned(n downto 0); -- length n+1
        variable ret  : l'subtype;
    begin
        tmp3 := resize(l.r3, tmp3'length) - resize(r.r3, tmp3'length);

        ret.r1 := sub_mod2Nm1(l.r1, r.r1);
        ret.r2 := sub_mod2Nm1(l.r2, r.r2);
        ret.r3 := tmp3(ret.r3'length-1 downto 0);
        ret.r4 := sub_mod2Np1(l.r4, r.r4);
        ret.r5 := sub_mod2Nm1(l.r5, r.r5);
        return ret;
    end function "-";


    function "-" (l, r : rrns5_signed) return rrns5_signed is
    begin
        return to_rrns5_signed(to_rrns5_unsigned(l) - to_rrns5_unsigned(r));
    end function;


    function "-" (l, r : rrns5_sfixed) return rrns5_sfixed is
        variable result : l'subtype;
    begin

        assert l.comma = r.comma report "The integer and fractional parts must match for subtraction in RRNS." severity failure;
        
        result.number := l.number - r.number;
        result.comma  := l.comma;

        return result;
    end function;


    function "*" (l, r : rrns5_unsigned) return rrns5_unsigned is
        constant n    : natural := l.r3'length;
        variable tmp3 : unsigned(2*n-1 downto 0);
        variable ret  : l'subtype;
    begin
        tmp3 := l.r3 * r.r3;

        ret.r1 := mul_mod2Nm1(l.r1, r.r1);
        ret.r2 := mul_mod2Nm1(l.r2, r.r2);
        ret.r3 := tmp3(ret.r3'length-1 downto 0);
        ret.r4 := mul_mod2Np1(l.r4, r.r4);
        ret.r5 := mul_mod2Nm1(l.r5, r.r5);
        return ret;
    end function "*";


    function "*" (l, r : rrns5_signed) return rrns5_signed is
    begin
        return to_rrns5_signed(to_rrns5_unsigned(l) * to_rrns5_unsigned(r));
    end function;


    function "*" (l, r : rrns5_sfixed) return rrns5_sfixed is
        variable result : l'subtype;
    begin

        result.comma  := l.comma + r.comma; -- the new type has the comma further to the left
        result.number := l.number * r.number;

        return result;
    end function;


    function to_unsigned (arg : rrns5_unsigned; size : natural) return unsigned is
        constant n : natural := arg.r3'length;
        variable ret : unsigned(3*n-2 downto 0);
    begin
        ret := r1r2r3_2bin(arg.r1, arg.r2, arg.r3);
        return resize(ret, size);
    end function;


    function to_signed (arg : rrns5_signed; size : natural) return signed is
        constant n : natural := arg.r3'length;
        variable rotated : unsigned(3*n-2 downto 0);
        variable result : signed(3*n downto 0);
    begin
        rotated := r1r2r3_2bin(arg.r1, arg.r2, arg.r3);

        if rotated >= shift_right(rrns5_redundant_range_u(n), 1) then
            -- Negative number -> rotate back
            result := resize(
                    signed(resize(rotated, result'length))
                    - signed(resize(rrns5_redundant_range_u(n), result'length)),
                result'length
                ); -- maximum dynamic range of the reverse conversion
        else
            result := signed(resize(rotated, result'length));
        end if;

        return resize(result, size);

    end function;


    function to_sfixed (arg : rrns5_sfixed; higher, lower : integer) return sfixed is
        constant n : natural := arg.number.r3'length;
        constant possible_len : natural := rrns5_redundant_range_length(n);
        constant comma : natural := arg.comma;
        --variable full_range : sfixed(possible_len-1 downto -comma) := (others => '0'); -- Quartus does not seem to support a constant from a record here...
        variable full_range : sfixed(possible_len-1 downto -(possible_len+1)) := (others => '0'); -- this is way too large but quartus can optimize this later
    begin

        full_range := to_sfixed(to_signed(arg.number, possible_len), full_range); -- With size of full_range

        -- Shift by comma
        full_range := shift_right(full_range, comma);

        return resize(full_range, higher, lower);

    end function;


    function to_rrns5_signed(i : rrns5_unsigned) return rrns5_signed is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(rrns5_modulo_n(i));
        variable rrns_out : rrns5_signed(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r4(RRNS_LENS(4)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
    begin
        rrns_out.r1 := i.r1;
        rrns_out.r2 := i.r2;
        rrns_out.r3 := i.r3;
        rrns_out.r4 := i.r4;
        rrns_out.r5 := i.r5;
        return rrns_out;
    end function;


    function to_rrns5_unsigned(i : rrns5_signed) return rrns5_unsigned is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(rrns5_modulo_n(i));
        variable rrns_out : rrns5_unsigned(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r4(RRNS_LENS(4)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
    begin
        rrns_out.r1 := i.r1;
        rrns_out.r2 := i.r2;
        rrns_out.r3 := i.r3;
        rrns_out.r4 := i.r4;
        rrns_out.r5 := i.r5;
        return rrns_out;
    end function;


    function rrns5_modulo_n(r : rrns5_unsigned) return natural is
    begin
        return r.r3'length;
    end function;


    function rrns5_modulo_n(r : rrns5_signed) return natural is
    begin
        return r.r3'length;
    end function;


    function rrns5_modulo_n(r : rrns5_sfixed) return natural is
    begin
        return r.number.r3'length;
    end function;


    function rrns_is_erroneus(r : rrns5_unsigned; num : unsigned) return std_ulogic is
        constant n      : natural := rrns5_modulo_n(r);
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(rrns5_modulo_n(r));
        --variable comp    : r'subtype; -- Questa crashes with unknown error here...
        variable comp : rrns5_unsigned(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r4(RRNS_LENS(4)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
    begin
        comp := to_rrns5_unsigned(num, n);

        if(comp.r4 /= r.r4 or comp.r5 /= r.r5) then
            return '1';
        else
            return '0';
        end if;
    end function;


    function rrns_is_erroneus(r : rrns5_signed; num : signed) return std_ulogic is
        constant n      : natural := rrns5_modulo_n(r);
        -- variable comp   : r'subtype; -- Questa crashes with unknown error here...
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(rrns5_modulo_n(r));
        variable comp : rrns5_signed(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r4(RRNS_LENS(4)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
    begin
        comp := to_rrns5_signed(num, n);
        if(comp.r4 /= r.r4 or comp.r5 /= r.r5) then
            return '1';
        else
            return '0';
        end if;
    end function;


    function rrns_is_erroneus(r : rrns5_sfixed; num : sfixed) return std_ulogic is
        constant n      : natural := rrns5_modulo_n(r);
        --variable comp   : r'subtype; -- Questa crashes with unknown error here...
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        variable comp : rrns5_sfixed(number(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r4(RRNS_LENS(4)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0)));
    begin
        comp := to_rrns5_sfixed(num, n);
        if(comp.number.r4 /= r.number.r4 or comp.number.r5 /= r.number.r5) then
            return '1';
        else
            return '0';
        end if;
    end function;


    function to_sulv(r : rrns5_unsigned) return std_ulogic_vector is
    begin
        return std_ulogic_vector(r.r5)
            & std_ulogic_vector(r.r4)
            & std_ulogic_vector(r.r3)
            & std_ulogic_vector(r.r2)
            & std_ulogic_vector(r.r1);
    end function;


    function to_sulv(r : rrns5_signed) return std_ulogic_vector is
    begin
        return std_ulogic_vector(r.r5)
            & std_ulogic_vector(r.r4)
            & std_ulogic_vector(r.r3)
            & std_ulogic_vector(r.r2)
            & std_ulogic_vector(r.r1);
    end function;


    function to_sulv(r : rrns5_sfixed) return std_ulogic_vector is
    begin
        return std_ulogic_vector(r.number.r5)
            & std_ulogic_vector(r.number.r4)
            & std_ulogic_vector(r.number.r3)
            & std_ulogic_vector(r.number.r2)
            & std_ulogic_vector(r.number.r1);
    end function;


    ----------------------------------------------------------------------------
    -- RRNS R4
    ----------------------------------------------------------------------------


    function rrns_residues_to_string(r : rrns4_unsigned) return string is
    begin
        return "<" &
            to_string(to_integer(r.r1)) & ", " &
            to_string(to_integer(r.r2)) & ", " &
            to_string(to_integer(r.r3)) & ", " &
            to_string(to_integer(r.r5)) & ">";
    end function;


    function to_string(r : rrns4_unsigned) return string is
    begin
        return "rrns4_unsigned" & rrns_residues_to_string(r);
    end function;


    function to_string(r : rrns4_signed) return string is
    begin
        return "rrns4_signed" & rrns_residues_to_string(to_rrns4_unsigned(r));
    end function;


    function to_string(r : rrns4_sfixed) return string is
    begin
        return to_string(r.number) & "_Comma=" & to_string(r.comma);
    end function;


    function rrns4_redundant_range_length(n : natural) return natural is
    begin
        return 3*n;
    end function;


    function rrns4_redundant_range_u(r : rrns4_unsigned) return unsigned is
        constant n : natural := rrns4_modulo_n(r);
    begin
        return rrns4_redundant_range_u(n);
    end function;


    function rrns4_redundant_range_u(n : natural) return unsigned is
        variable ret : unsigned(rrns4_redundant_range_length(n)-1 downto 0);
    begin
        ret := shift_left(to_unsigned(1, ret'length), n-1) - to_unsigned(1, ret'length); -- 2**(n-1) - 1
        ret := resize(ret * (shift_left(to_unsigned(1, ret'length), n) - to_unsigned(1, ret'length)), ret'length); -- 2**(n) - 1
        ret := resize(ret * (shift_left(to_unsigned(1, ret'length), n)), ret'length); -- 2**(n)
        return ret;
    end function;


    function rrns4_range_u(r : rrns4_unsigned) return unsigned is
        constant n : natural := rrns4_modulo_n(r);
    begin
        return rrns4_range_u(n);
    end function;


    function rrns4_range_u(n : natural) return unsigned is
        variable ret : unsigned(rrns4_range_length(n)-1 downto 0);
    begin
        ret := shift_left(to_unsigned(1, ret'length), n-1) - to_unsigned(1, ret'length); -- 2**(n-1) - 1
        ret := resize(ret * (shift_left(to_unsigned(1, ret'length), n) - to_unsigned(1, ret'length)), ret'length); -- 2**(n) - 1
        ret := resize(ret * (shift_left(to_unsigned(1, ret'length), n)), ret'length); -- 2**(n)
        ret := resize(ret * (shift_left(to_unsigned(1, ret'length), n+1) - to_unsigned(1, ret'length)), ret'length); -- 2**(n+1) - 1
        return ret;
    end function;


    function rrns4_range_length(n : natural) return natural is
    begin
        return 4*n;
    end function;


    function to_rrns4_unsigned (arg : natural; n : natural) return rrns4_unsigned is
        constant num : unsigned(3*n+1 downto 0) := to_unsigned(arg, 3*n+2);
    begin

        assert to_unsigned(arg, rrns4_redundant_range_length(n)) < rrns4_redundant_range_u(n)
            report "Number too large for redundant RRNS range. May move to illegitimate range!" severity warning;

        return to_rrns4_unsigned(num, n);

    end function;


    function to_rrns4_unsigned(arg: unsigned; n : natural) return rrns4_unsigned is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        constant n_zeros : unsigned(n-1 downto 0) := (others => '0');
        variable b_in : unsigned(rrns4_range_length(n)-1 downto 0);
        variable rrns_out : rrns4_unsigned(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));

        variable k1_0, k1_1, k1_2, k1_3, k1_4, k1_5 : unsigned(n-2 downto 0);
        variable k2_0, k2_1, k2_2, k2_3, k2_4 : unsigned(n-1 downto 0);
        variable k3_0, k3_1, k3_2, k3_3, k3_4 : unsigned(n downto 0);
        variable k2_0_n, k2_1_n, k2_2_n, k2_3_n, k2_4_n : unsigned(n downto 0);

        variable r1_0, r1_1, r1_2, r1_3 : unsigned(n-2 downto 0);
        variable r2_0, r2_1, r2_2: unsigned(n-1 downto 0);
        variable r5_0, r5_1, r5_2: unsigned(n downto 0);

    begin

        assert n >= 6 report "The moduli set paramater n must be equal to or larger than 6" severity error;
        assert n mod 2 = 0 report "The moduli set paramater n must be an even integer" severity error;

        b_in := resize(arg, b_in'length); -- Length 5n

        -- Partition the number into parts of (n-1) bits
        k1_0 := b_in(n-2 downto 0);
        k1_1 := b_in(2*n-3 downto n-1);
        k1_2 := b_in(3*n-4 downto 2*n-2);
        k1_3 := b_in(4*n-5 downto 3*n-3);
        k1_4 := resize(b_in(b_in'high downto 4*n-4), k1_4'length);

        -- Partition the number into parts of n bits
        k2_0 := b_in(n-1 downto 0);
        k2_1 := b_in(2*n-1 downto n);
        k2_2 := b_in(3*n-1 downto 2*n);
        k2_3 := b_in(4*n-1 downto 3*n);

        -- Partition the number into parts of n+1 bits
        k3_0 := b_in(n downto 0);
        k3_1 := b_in(2*n+1 downto n+1);
        k3_2 := b_in(3*n+2 downto 2*n+2);
        k3_3 := resize(b_in(b_in'high downto 3*n+3), k3_3'length);

        -- Easy residue 3
        rrns_out.r3 := k2_0;

        -- r1 = (k1_0 + k1_1 + k1_2 + k1_3 + k1_4) mod 2^(n-1) - 1:
        -- Adder tree
        r1_0 := add_mod2Nm1(k1_0, k1_1); --A
        r1_1 := add_mod2Nm1(k1_2, k1_3); --B
        r1_3 := add_mod2Nm1(r1_1, k1_4); --B+k1_4

        rrns_out.r1 := add_mod2Nm1(r1_0, r1_3); -- A+B+C


        -- r2 = (k2_0 + k2_1 + k2_2 + k2_3) mod 2^n - 1:
        r2_0 := add_mod2Nm1(k2_0, k2_1); --A
        r2_1 := add_mod2Nm1(k2_2, k2_3); --B

        rrns_out.r2 := resize(add_mod2Nm1(r2_0, r2_1), rrns_out.r2'length);


        -- r5 = (k3_0 + k3_1 + k3_2 + k3_3) mod 2^(n+1) - 1:
        r5_0 := add_mod2Nm1(k3_0, k3_1); -- A
        r5_1 := add_mod2Nm1(k3_2, k3_3); -- B

        rrns_out.r5 := add_mod2Nm1(r5_0, r5_1);

        return rrns_out;

    end function;


    function to_rrns4_unsigned (arg : std_ulogic_vector; n : natural) return rrns4_unsigned is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        variable result : rrns4_unsigned(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
        variable upper : natural;
    begin
        result.r1 := unsigned(arg(RRNS_LENS(1)-1 downto 0));
        upper := RRNS_LENS(1);
        result.r2 := unsigned(arg(upper+RRNS_LENS(2)-1 downto upper));
        upper := upper + RRNS_LENS(2);
        result.r3 := unsigned(arg(upper+RRNS_LENS(3)-1 downto upper));
        upper := upper + RRNS_LENS(3);
        result.r5 := unsigned(arg(upper+RRNS_LENS(5)-1 downto upper));
        return result;
    end function;



    function to_rrns4_signed (arg : signed; n : natural) return rrns4_signed is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        variable rrns_intermediate : rrns4_unsigned(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
        variable rotated : signed(rrns4_range_length(n) downto 0);
    begin

        -- If the number is smaller than 0 we have to shift it to negative
        if arg < 0 then -- Check if the synthesizer is clever and just checks the sign bit
            rotated := resize(signed(rrns4_range_u(n)), rrns4_range_length(n)+1) + arg;

            rrns_intermediate := to_rrns4_unsigned(unsigned(rotated), n); -- Add arg as the number is negative
        else
            rrns_intermediate := to_rrns4_unsigned(unsigned(arg), n);
        end if;

        return to_rrns4_signed(rrns_intermediate);

        -- There is an alternative to this: subtract the constant RRNS number "rrnsRange/2" after converting the abs
        -- This would also protect the conversion process more as it is redundant

    end function;



    function to_rrns4_signed (arg : std_ulogic_vector; n : natural) return rrns4_signed is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        variable result : rrns4_signed(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
        variable upper : natural;
    begin
        result.r1 := unsigned(arg(RRNS_LENS(1)-1 downto 0));
        upper := RRNS_LENS(1);
        result.r2 := unsigned(arg(upper+RRNS_LENS(2)-1 downto upper));
        upper := upper + RRNS_LENS(2);
        result.r3 := unsigned(arg(upper+RRNS_LENS(3)-1 downto upper));
        upper := upper + RRNS_LENS(3);
        result.r5 := unsigned(arg(upper+RRNS_LENS(5)-1 downto upper));
        return result;
    end function;



    function to_rrns4_sfixed (arg : sfixed  ; n : natural) return rrns4_sfixed is
        constant len      : natural := arg'length;
        constant comma    : natural := -arg'low;
        variable shifted  : sfixed(len downto arg'low);

        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        variable result   : rrns4_sfixed(
                number(
                r1(RRNS_LENS(1)-1 downto 0),
                r2(RRNS_LENS(2)-1 downto 0),
                r3(RRNS_LENS(3)-1 downto 0),
                r5(RRNS_LENS(5)-1 downto 0))
            );
    begin

        shifted := shift_left(resize(arg, len, arg'low), comma);

        result.number := to_rrns4_signed(signed(shifted(len-1 downto 0)), n);
        result.comma  := comma;

        return result;

    end function;



    function to_rrns4_sfixed (arg : std_ulogic_vector; n : natural; comma : natural) return rrns4_sfixed is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(n);
        variable result   : rrns4_sfixed(
                number(
                r1(RRNS_LENS(1)-1 downto 0),
                r2(RRNS_LENS(2)-1 downto 0),
                r3(RRNS_LENS(3)-1 downto 0),
                r5(RRNS_LENS(5)-1 downto 0))
            );
        variable upper : natural;
    begin
        result.number.r1 := unsigned(arg(RRNS_LENS(1)-1 downto 0));
        upper := RRNS_LENS(1);
        result.number.r2 := unsigned(arg(upper+RRNS_LENS(2)-1 downto upper));
        upper := upper + RRNS_LENS(2);
        result.number.r3 := unsigned(arg(upper+RRNS_LENS(3)-1 downto upper));
        upper := upper + RRNS_LENS(3);
        result.number.r5 := unsigned(arg(upper+RRNS_LENS(5)-1 downto upper));

        result.comma := comma;

        return result;
    end function;


    function "+" (l, r : rrns4_unsigned) return rrns4_unsigned is
        constant n    : natural := l.r3'length;
        variable tmp3 : unsigned(n downto 0); -- length n+1
        variable ret  : l'subtype;
    begin
        tmp3 := resize(l.r3, tmp3'length) + resize(r.r3, tmp3'length);

        ret.r1 := add_mod2Nm1(l.r1, r.r1);
        ret.r2 := add_mod2Nm1(l.r2, r.r2);
        ret.r3 := tmp3(ret.r3'length-1 downto 0);
        ret.r5 := add_mod2Nm1(l.r5, r.r5);
        return ret;
    end function "+";


    function "+" (l, r : rrns4_signed) return rrns4_signed is
    begin
        return to_rrns4_signed(to_rrns4_unsigned(l) + to_rrns4_unsigned(r));
    end function;


    function "+" (l, r : rrns4_sfixed) return rrns4_sfixed is
        variable result : l'subtype;
    begin

        assert l.comma = r.comma report "The integer and fractional parts must match for addition in RRNS." severity failure;
        
        result.number := l.number + r.number;
        result.comma  := l.comma;

        return result;
    end function;


    function "-" (l, r : rrns4_unsigned) return rrns4_unsigned is
        constant n    : natural := l.r3'length;
        variable tmp3 : unsigned(n downto 0); -- length n+1
        variable ret  : l'subtype;
    begin
        tmp3 := resize(l.r3, tmp3'length) - resize(r.r3, tmp3'length);

        ret.r1 := sub_mod2Nm1(l.r1, r.r1);
        ret.r2 := sub_mod2Nm1(l.r2, r.r2);
        ret.r3 := tmp3(ret.r3'length-1 downto 0);
        ret.r5 := sub_mod2Nm1(l.r5, r.r5);
        return ret;
    end function "-";


    function "-" (l, r : rrns4_signed) return rrns4_signed is
    begin
        return to_rrns4_signed(to_rrns4_unsigned(l) - to_rrns4_unsigned(r));
    end function;


    function "-" (l, r : rrns4_sfixed) return rrns4_sfixed is
        variable result : l'subtype;
    begin

        assert l.comma = r.comma report "The integer and fractional parts must match for subtraction in RRNS." severity failure;
        
        result.number := l.number - r.number;
        result.comma  := l.comma;

        return result;
    end function;


    function "*" (l, r : rrns4_unsigned) return rrns4_unsigned is
        constant n    : natural := l.r3'length;
        variable tmp3 : unsigned(2*n-1 downto 0);
        variable ret  : l'subtype;
    begin
        tmp3 := l.r3 * r.r3;

        ret.r1 := mul_mod2Nm1(l.r1, r.r1);
        ret.r2 := mul_mod2Nm1(l.r2, r.r2);
        ret.r3 := tmp3(ret.r3'length-1 downto 0);
        ret.r5 := mul_mod2Nm1(l.r5, r.r5);
        return ret;
    end function "*";


    function "*" (l, r : rrns4_signed) return rrns4_signed is
    begin
        return to_rrns4_signed(to_rrns4_unsigned(l) * to_rrns4_unsigned(r));
    end function;


    function "*" (l, r : rrns4_sfixed) return rrns4_sfixed is
        variable result : l'subtype;
    begin

        result.comma  := l.comma + r.comma; -- the new type has the comma further to the left
        result.number := l.number * r.number;

        return result;
    end function;


    function to_unsigned (arg : rrns4_unsigned; size : natural) return unsigned is
        constant n : natural := arg.r3'length;
        variable ret : unsigned(3*n-2 downto 0);
    begin
        ret := r1r2r3_2bin(arg.r1, arg.r2, arg.r3);
        return resize(ret, size);
    end function;


    function to_signed (arg : rrns4_signed; size : natural) return signed is
        constant n : natural := arg.r3'length;
        variable rotated : unsigned(3*n-2 downto 0);
        variable result : signed(3*n downto 0);
    begin
        rotated := r1r2r3_2bin(arg.r1, arg.r2, arg.r3);

        if rotated >= shift_right(rrns4_redundant_range_u(n), 1) then
            -- Negative number -> rotate back
            result := resize(
                    signed(resize(rotated, result'length))
                    - signed(resize(rrns4_redundant_range_u(n), result'length)),
                result'length
                ); -- maximum dynamic range of the reverse conversion
        else
            result := signed(resize(rotated, result'length));
        end if;

        return resize(result, size);

    end function;


    function to_sfixed (arg : rrns4_sfixed; higher, lower : integer) return sfixed is
        constant n : natural := arg.number.r3'length;
        constant possible_len : natural := rrns4_redundant_range_length(n);
        constant comma : natural := arg.comma;
        variable full_range : sfixed(possible_len-1 downto -(possible_len+1)) := (others => '0'); -- this is way too large but the synthesizer can optimize this later
    begin

        full_range := to_sfixed(to_signed(arg.number, possible_len), full_range); -- With size of full_range

        -- Shift by comma
        full_range := shift_right(full_range, comma);

        return resize(full_range, higher, lower);

    end function;


    function to_rrns4_signed(i : rrns4_unsigned) return rrns4_signed is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(rrns4_modulo_n(i));
        variable rrns_out : rrns4_signed(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
    begin
        rrns_out.r1 := i.r1;
        rrns_out.r2 := i.r2;
        rrns_out.r3 := i.r3;
        rrns_out.r5 := i.r5;
        return rrns_out;
    end function;


    function to_rrns4_unsigned(i : rrns4_signed) return rrns4_unsigned is
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(rrns4_modulo_n(i));
        variable rrns_out : rrns4_unsigned(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
    begin
        rrns_out.r1 := i.r1;
        rrns_out.r2 := i.r2;
        rrns_out.r3 := i.r3;
        rrns_out.r5 := i.r5;
        return rrns_out;
    end function;


    function rrns4_modulo_n(r : rrns4_unsigned) return natural is
    begin
        return r.r3'length;
    end function;


    function rrns4_modulo_n(r : rrns4_signed) return natural is
    begin
        return r.r3'length;
    end function;


    function rrns4_modulo_n(r : rrns4_sfixed) return natural is
    begin
        return r.number.r3'length;
    end function;


    function rrns_is_erroneus(r : rrns4_unsigned; num : unsigned) return std_ulogic is
        constant n      : natural := rrns4_modulo_n(r);
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(rrns4_modulo_n(r));
        --variable comp    : r'subtype; -- Questa crashes with unknown error here...
        variable comp : rrns4_unsigned(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
    begin
        comp := to_rrns4_unsigned(num, n);
        if(comp.r5 /= r.r5) then
            return '1';
        else
            return '0';
        end if;
    end function;


    function rrns_is_erroneus(r : rrns4_signed; num : signed) return std_ulogic is
        constant n      : natural := rrns4_modulo_n(r);
        -- variable comp   : r'subtype; -- Questa crashes with unknown error here...
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(rrns4_modulo_n(r));
        variable comp : rrns4_signed(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0));
    begin
        comp := to_rrns4_signed(num, n);
        if(comp.r5 /= r.r5) then
            return '1';
        else
            return '0';
        end if;
    end function;


    function rrns_is_erroneus(r : rrns4_sfixed; num : sfixed) return std_ulogic is
        constant n      : natural := rrns4_modulo_n(r);
        --variable comp   : r'subtype; -- Questa crashes with unknown error here...
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(rrns4_modulo_n(r));
        variable comp : rrns4_sfixed(number(
            r1(RRNS_LENS(1)-1 downto 0),
            r2(RRNS_LENS(2)-1 downto 0),
            r3(RRNS_LENS(3)-1 downto 0),
            r5(RRNS_LENS(5)-1 downto 0)));
    begin
        comp := to_rrns4_sfixed(num, n);
        if(comp.number.r5 /= r.number.r5) then
            return '1';
        else
            return '0';
        end if;
    end function;


    function to_sulv(r : rrns4_unsigned) return std_ulogic_vector is
    begin
        return std_ulogic_vector(r.r5)
            & std_ulogic_vector(r.r3)
            & std_ulogic_vector(r.r2)
            & std_ulogic_vector(r.r1);
    end function;


    function to_sulv(r : rrns4_signed) return std_ulogic_vector is
    begin
        return std_ulogic_vector(r.r5)
            & std_ulogic_vector(r.r3)
            & std_ulogic_vector(r.r2)
            & std_ulogic_vector(r.r1);
    end function;


    function to_sulv(r : rrns4_sfixed) return std_ulogic_vector is
    begin
        return std_ulogic_vector(r.number.r5)
            & std_ulogic_vector(r.number.r3)
            & std_ulogic_vector(r.number.r2)
            & std_ulogic_vector(r.number.r1);
    end function;


end package body rrns_arith_lib;
