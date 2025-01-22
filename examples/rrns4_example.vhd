library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library rrns_arith_lib;
use rrns_arith_lib.rrns_arith_lib.all;

entity rrns4_example is
    port (
        input1 : in  unsigned(47 downto 0);
        input2 : in  unsigned(47 downto 0);
        output : out unsigned(47 downto 0);
        fault  : out std_ulogic
    );
end entity rrns4_example;

architecture rtl of rrns4_example is

    -- Define the modulo parameter N and calculate the RRNS moduli lengths from it
    constant N : natural := 16;
    constant RRNS_LENGTHS : rrns_lengths_t := rrns_residue_lengths(N);

    -- Fully constraint the RRNS type's residues for synthesis
    -- The length comes from the constant
    signal input1_rrns : rrns4_unsigned(
            r1(RRNS_LENGTHS(1)-1 downto 0),
            r2(RRNS_LENGTHS(2)-1 downto 0),
            r3(RRNS_LENGTHS(3)-1 downto 0),
            r5(RRNS_LENGTHS(5)-1 downto 0)
        );

    -- The same types as input1_rrns
    signal input2_rrns : input1_rrns'subtype;
    signal output_rrns : input1_rrns'subtype;

begin

    -- Convert the inputs to RRNS
    input1_rrns <= to_rrns4_unsigned(input1, N);
    input2_rrns <= to_rrns4_unsigned(input2, N);

    -- Do some calculation with the numbers
    output_rrns <= input1_rrns + input2_rrns;

    -- Reconvert the RRNS number to common binary representation
    output <= to_unsigned(output_rrns, output'length);

    -- Check integrity of the number
    fault <= rrns_is_erroneus(output_rrns, output);
    
end architecture rtl;
