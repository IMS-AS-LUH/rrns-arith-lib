--------------------------------------------------------------------------------
-- Title       : RRNS Arithmetic Library RRNS5 Testbench
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

library rrns_arith_lib;
use rrns_arith_lib.rrns_arith_lib.all;

library vunit_lib;
context vunit_lib.vunit_context;

library OSVVM ; 
use OSVVM.RandomBasePkg.all;
use OSVVM.RandomPkg.all;

-----------------------------------------------------------

entity rrns5_test is
    generic (
        runner_cfg : string
    );
end entity rrns5_test;

-----------------------------------------------------------

architecture testbench of rrns5_test is

    impure function injectError(r : rrns5_unsigned; faulty_residue, faulty_bit : natural) return rrns5_unsigned is
        constant n : natural := rrns5_modulo_n(r);
        constant RRNS_LENS : rrns_lengths_t := rrns_residue_lengths(rrns5_modulo_n(r));
        variable ret : r'subtype;
        variable faulty_bit_mod : natural;
    begin

        ret := r;

        faulty_bit_mod := faulty_bit MOD RRNS_LENS(faulty_residue);

        case faulty_residue is
            when 1 => ret.r1(faulty_bit_mod) := not ret.r1(faulty_bit_mod);
            when 2 => ret.r2(faulty_bit_mod) := not ret.r2(faulty_bit_mod);
            when 3 => ret.r3(faulty_bit_mod) := not ret.r3(faulty_bit_mod);
            when 4 => ret.r4(faulty_bit_mod) := not ret.r4(faulty_bit_mod);
            when 5 => ret.r5(faulty_bit_mod) := not ret.r5(faulty_bit_mod);
            when others => null;
        end case;

        return ret;

    end function;

    impure function injectError(r : rrns5_signed; faulty_residue, faulty_bit : natural) return rrns5_signed is
    begin
        return to_rrns5_signed(injectError(to_rrns5_unsigned(r), faulty_residue, faulty_bit));
    end function;

    -- Use naturals here for small numbers
    function rrns5RedundantRange(r : rrns5_unsigned) return natural is
    begin
        return to_integer(rrns5_redundant_range_u(r));
    end function;

begin

    test_runner_watchdog(runner, 60 sec);

    main : process

        variable n : natural := 0;

        variable RV : RandomPType;

        constant lens_n6 : rrns_lengths_t := rrns_residue_lengths(6);
        variable rrns_n6 : rrns5_unsigned(
            r1(lens_n6(1)-1 downto 0),
            r2(lens_n6(2)-1 downto 0),
            r3(lens_n6(3)-1 downto 0),
            r4(lens_n6(4)-1 downto 0),
            r5(lens_n6(5)-1 downto 0));
        variable rrns_n6_2 : rrns5_unsigned(
            r1(lens_n6(1)-1 downto 0),
            r2(lens_n6(2)-1 downto 0),
            r3(lens_n6(3)-1 downto 0),
            r4(lens_n6(4)-1 downto 0),
            r5(lens_n6(5)-1 downto 0));

        constant lens_n8 : rrns_lengths_t := rrns_residue_lengths(8);
        variable rrns_n8 : rrns5_unsigned(
            r1(lens_n8(1)-1 downto 0),
            r2(lens_n8(2)-1 downto 0),
            r3(lens_n8(3)-1 downto 0),
            r4(lens_n8(4)-1 downto 0),
            r5(lens_n8(5)-1 downto 0));

        variable binary1 : natural := 0;
        variable binary2 : natural := 0;
        variable binary3 : natural := 0;


        -- signed
        variable signed1 : integer := 0;
        variable signed2 : integer := 0;
        variable signed3 : integer := 0;

        variable srrns_n6 : rrns5_signed(
            r1(lens_n6(1)-1 downto 0),
            r2(lens_n6(2)-1 downto 0),
            r3(lens_n6(3)-1 downto 0),
            r4(lens_n6(4)-1 downto 0),
            r5(lens_n6(5)-1 downto 0));
        variable srrns_n6_2 : rrns5_signed(
            r1(lens_n6(1)-1 downto 0),
            r2(lens_n6(2)-1 downto 0),
            r3(lens_n6(3)-1 downto 0),
            r4(lens_n6(4)-1 downto 0),
            r5(lens_n6(5)-1 downto 0));

        -- signed fixed-point
        variable sfixed1_n6 : sfixed(3*6+1 downto -(3*6+2)) := (others => '0');
        variable sfixed2_n6 : sfixed(3*6+1 downto -(3*6+2));
        variable sfixed3_n6 : sfixed(3*6+1 downto -(3*6+2));
        variable sfxrrns_n6 : rrns5_sfixed(
            number(
            r1(lens_n6(1)-1 downto 0),
            r2(lens_n6(2)-1 downto 0),
            r3(lens_n6(3)-1 downto 0),
            r4(lens_n6(4)-1 downto 0),
            r5(lens_n6(5)-1 downto 0)));
        variable sfxrrns_n6_2 : rrns5_sfixed(
            number(
            r1(lens_n6(1)-1 downto 0),
            r2(lens_n6(2)-1 downto 0),
            r3(lens_n6(3)-1 downto 0),
            r4(lens_n6(4)-1 downto 0),
            r5(lens_n6(5)-1 downto 0)));
        variable sfxrrns_n6_3 : rrns5_sfixed(
            number(
            r1(lens_n6(1)-1 downto 0),
            r2(lens_n6(2)-1 downto 0),
            r3(lens_n6(3)-1 downto 0),
            r4(lens_n6(4)-1 downto 0),
            r5(lens_n6(5)-1 downto 0)));

        -- Fault Injection
        variable faulty_bit : natural;
        variable faulty_residue : natural;

    begin

        test_runner_setup(runner, runner_cfg);

        RV.InitSeed(RV'instance_name);

        while test_suite loop

            if run("test_forward_conversion_full_redundant_range_n6") then

                n := 6;

                for i in 0 to rrns5RedundantRange(rrns_n6)-1 loop
                    rrns_n6 := to_rrns5_unsigned(to_unsigned(i, 3*n+2), n);

                    check(rrns_n6.r1 = i mod ((2**(n - 1))-1), "Residue 1 fails");
                    check(rrns_n6.r2 = i mod ((2**n)-1), "Residue 2 fails");
                    check(rrns_n6.r3 = i mod ((2**n)), "Residue 3 fails");
                    check(rrns_n6.r4 = i mod ((2**n)+1), "Residue 4 fails");
                    check(rrns_n6.r5 = i mod ((2**(n + 1))-1), "Residue 5 fails");
                end loop;

            elsif run("test_random_addition_redundant_range_n6") then

                n := 6;

                for i in 0 to 500_000 loop

                    binary1 := RV.RandInt(0, rrns5RedundantRange(rrns_n6)-1); -- Result
                    binary2 := RV.RandInt(0, binary1); -- Summand 1
                    binary3 := binary1 - binary2; -- Summand 2

                    rrns_n6   := to_rrns5_unsigned(to_unsigned(binary2, 3*n+2), n);
                    rrns_n6_2 := to_rrns5_unsigned(to_unsigned(binary3, 3*n+2), n);

                    rrns_n6 := rrns_n6 + rrns_n6_2;

                    check(rrns_n6.r1 = binary1 mod ((2**(n - 1))-1), "Residue 1 fails");
                    check(rrns_n6.r2 = binary1 mod ((2**n)-1), "Residue 2 fails");
                    check(rrns_n6.r3 = binary1 mod ((2**n)), "Residue 3 fails");
                    check(rrns_n6.r4 = binary1 mod ((2**n)+1), "Residue 4 fails");
                    check(rrns_n6.r5 = binary1 mod ((2**(n + 1))-1), "Residue 5 fails");
                end loop;

            elsif run("test_random_subtraction_redundant_range_n6") then

                n := 6;

                for i in 0 to 500_000 loop

                    binary1 := RV.RandInt(0, rrns5RedundantRange(rrns_n6)-1); -- Result
                    binary2 := RV.RandInt(binary1, rrns5RedundantRange(rrns_n6)-1); -- Minuend, larger than binary1
                    binary3 := binary2 - binary1; -- Subtrahend

                    rrns_n6   := to_rrns5_unsigned(to_unsigned(binary2, 3*n+2), n);
                    rrns_n6_2 := to_rrns5_unsigned(to_unsigned(binary3, 3*n+2), n);

                    rrns_n6 := rrns_n6 - rrns_n6_2;

                    check(rrns_n6.r1 = binary1 mod ((2**(n - 1))-1));
                    check(rrns_n6.r2 = binary1 mod ((2**n)-1));
                    check(rrns_n6.r3 = binary1 mod ((2**n)));
                    check(rrns_n6.r4 = binary1 mod ((2**n)+1));
                    check(rrns_n6.r5 = binary1 mod ((2**(n + 1))-1));
                end loop;

            elsif run("test_random_multiplication_redundant_range_n6") then

                n := 6;

                for i in 0 to 500_000 loop

                    binary1 := RV.RandInt(1, rrns5RedundantRange(rrns_n6)-1); -- Result
                    binary2 := RV.RandInt(1, binary1); -- Multiplicand 1
                    -- Find the next integer divisable number
                    while binary1 mod binary2 /= 0 loop
                        binary2 := binary2 - 1;
                    end loop;
                    binary3 := binary1 / binary2; -- Multiplicand 2

                    rrns_n6   := to_rrns5_unsigned(to_unsigned(binary2, 3*n+2), n);
                    rrns_n6_2 := to_rrns5_unsigned(to_unsigned(binary3, 3*n+2), n);

                    rrns_n6 := rrns_n6 * rrns_n6_2;

                    check(rrns_n6.r1 = binary1 mod ((2**(n - 1))-1), "Residue 1 fails");
                    check(rrns_n6.r2 = binary1 mod ((2**n)-1), "Residue 2 fails");
                    check(rrns_n6.r3 = binary1 mod ((2**n)), "Residue 3 fails");
                    check(rrns_n6.r4 = binary1 mod ((2**n)+1), "Residue 4 fails");
                    check(rrns_n6.r5 = binary1 mod ((2**(n + 1))-1), "Residue 5 fails");
                end loop;

            elsif run("test_random_addition_redundant_range_n6_signed") then

                n := 6;

                for i in 0 to 500_000 loop

                    signed1 := RV.RandInt(-rrns5RedundantRange(rrns_n6)/2, rrns5RedundantRange(rrns_n6)/2 - 1); -- Result
                    signed2 := RV.RandInt(-rrns5RedundantRange(rrns_n6)/2, signed1); -- Summand 1
                    signed3 := signed1 - signed2; -- Summand 2

                    srrns_n6   := to_rrns5_signed(to_signed(signed2, 3*n+2), n);
                    srrns_n6_2 := to_rrns5_signed(to_signed(signed3, 3*n+2), n);

                    srrns_n6 := srrns_n6 + srrns_n6_2;

                    check(srrns_n6.r1 = signed1 mod ((2**(n - 1))-1), "Residue 1 fails");
                    check(srrns_n6.r2 = signed1 mod ((2**n)-1), "Residue 2 fails");
                    check(srrns_n6.r3 = signed1 mod ((2**n)), "Residue 3 fails");
                    check(srrns_n6.r4 = signed1 mod ((2**n)+1), "Residue 4 fails");
                    check(srrns_n6.r5 = signed1 mod ((2**(n + 1))-1), "Residue 5 fails");
                end loop;

            elsif run("test_random_subtraction_redundant_range_n6_signed") then

                n := 6;

                for i in 0 to 500_000 loop

                    signed1 := RV.RandInt(-rrns5RedundantRange(rrns_n6)/2, rrns5RedundantRange(rrns_n6)/2 - 1); -- Result
                    signed2 := RV.RandInt(signed1, rrns5RedundantRange(rrns_n6)/2); -- Minuend (larger than result)
                    signed3 := signed2 - signed1; -- Subtrahend

                    srrns_n6   := to_rrns5_signed(to_signed(signed2, 3*n+2), n);
                    srrns_n6_2 := to_rrns5_signed(to_signed(signed3, 3*n+2), n);

                    srrns_n6 := srrns_n6 - srrns_n6_2;

                    check(srrns_n6.r1 = signed1 mod ((2**(n - 1))-1), "Residue 1 fails");
                    check(srrns_n6.r2 = signed1 mod ((2**n)-1), "Residue 2 fails");
                    check(srrns_n6.r3 = signed1 mod ((2**n)), "Residue 3 fails");
                    check(srrns_n6.r4 = signed1 mod ((2**n)+1), "Residue 4 fails");
                    check(srrns_n6.r5 = signed1 mod ((2**(n + 1))-1), "Residue 5 fails");
                end loop;

            elsif run("test_random_multiplication_redundant_range_n6_signed") then

                n := 6;

                for i in 0 to 500_000 loop

                    signed1 := RV.RandInt(1, rrns5RedundantRange(rrns_n6)-1); -- Result
                    signed2 := RV.RandInt(1, signed1); -- Multiplicand 1
                    -- Find the next integer divisable number
                    while signed1 mod signed2 /= 0 loop
                        signed2 := signed2 - 1;
                    end loop;
                    signed3 := signed1 / signed2; -- Multiplicand 2

                    srrns_n6   := to_rrns5_signed(to_signed(signed2, 3*n+2), n);
                    srrns_n6_2 := to_rrns5_signed(to_signed(signed3, 3*n+2), n);

                    srrns_n6 := srrns_n6 * srrns_n6_2;

                    check(srrns_n6.r1 = signed1 mod ((2**(n - 1))-1), "Residue 1 fails");
                    check(srrns_n6.r2 = signed1 mod ((2**n)-1), "Residue 2 fails");
                    check(srrns_n6.r3 = signed1 mod ((2**n)), "Residue 3 fails");
                    check(srrns_n6.r4 = signed1 mod ((2**n)+1), "Residue 4 fails");
                    check(srrns_n6.r5 = signed1 mod ((2**(n + 1))-1), "Residue 5 fails");
                end loop;


            elsif run("test_random_addition_redundant_range_n6_sfixed") then

                n := 6;

                for i in 0 to 500_000 loop

                    signed1 := RV.RandInt(-rrns5RedundantRange(rrns_n6)/2, rrns5RedundantRange(rrns_n6)/2 - 1); -- Result as integer
                    signed2 := RV.RandInt(-rrns5RedundantRange(rrns_n6)/2, signed1); -- Summand 1
                    signed3 := signed1 - signed2; -- Summand 2

                    -- Random comma position
                    binary1 := RV.RandInt(0, 3*n+1);
                    sfixed1_n6 := shift_right(to_sfixed(signed1, sfixed1_n6), binary1);
                    sfixed2_n6 := shift_right(to_sfixed(signed2, sfixed2_n6), binary1);
                    sfixed3_n6 := shift_right(to_sfixed(signed3, sfixed3_n6), binary1);

                    sfixed1_n6 := resize(sfixed2_n6 + sfixed3_n6, sfixed1_n6); -- result

                    sfxrrns_n6   := to_rrns5_sfixed(sfixed2_n6(3*n+1-binary1 downto -binary1), n);
                    sfxrrns_n6_2 := to_rrns5_sfixed(sfixed3_n6(3*n+1-binary1 downto -binary1), n);

                    sfxrrns_n6 := sfxrrns_n6 + sfxrrns_n6_2;

                    check(sfixed1_n6 = to_sfixed(sfxrrns_n6, sfixed1_n6'high, sfixed1_n6'low));

                end loop;

            elsif run("test_random_subtraction_redundant_range_n6_sfixed") then

                n := 6;

                for i in 0 to 500_000 loop

                    signed1 := RV.RandInt(-rrns5RedundantRange(rrns_n6)/2, rrns5RedundantRange(rrns_n6)/2 - 1); -- Result as integer
                    signed2 := RV.RandInt(signed1, rrns5RedundantRange(rrns_n6)/2); -- Minuend (larger than result)
                    signed3 := signed2 - signed1; -- Subtrahend

                    -- Random comma position
                    binary1 := RV.RandInt(0, 3*n+1);
                    sfixed1_n6 := shift_right(to_sfixed(signed1, sfixed1_n6), binary1);
                    sfixed2_n6 := shift_right(to_sfixed(signed2, sfixed2_n6), binary1);
                    sfixed3_n6 := shift_right(to_sfixed(signed3, sfixed3_n6), binary1);

                    sfixed1_n6 := resize(sfixed2_n6 - sfixed3_n6, sfixed1_n6); -- result

                    sfxrrns_n6   := to_rrns5_sfixed(sfixed2_n6(3*n+1-binary1 downto -binary1), n);
                    sfxrrns_n6_2 := to_rrns5_sfixed(sfixed3_n6(3*n+1-binary1 downto -binary1), n);

                    sfxrrns_n6 := sfxrrns_n6 - sfxrrns_n6_2;

                    check(sfixed1_n6 = to_sfixed(sfxrrns_n6, sfixed1_n6'high, sfixed1_n6'low));

                end loop;

            elsif run("test_random_multiplaction_n6_sfixed") then

                n := 6;

                for i in 0 to 500_000 loop

                    signed2 := RV.RandInt(-rrns5RedundantRange(rrns_n6)/1024, rrns5RedundantRange(rrns_n6)/1024 - 1); -- Multiplicand 1
                    signed3 := RV.RandInt(-rrns5RedundantRange(rrns_n6)/1024, rrns5RedundantRange(rrns_n6)/1024 - 1); -- Multiplicand 2

                    -- Random comma positions
                    binary1 := RV.RandInt(0, 3);
                    binary2 := RV.RandInt(0, 3);
                    sfixed2_n6 := shift_right(to_sfixed(signed2, sfixed2_n6), binary1);
                    sfixed3_n6 := shift_right(to_sfixed(signed3, sfixed3_n6), binary2);

                    sfixed1_n6 := resize(sfixed2_n6 * sfixed3_n6, sfixed1_n6); -- result

                    sfxrrns_n6   := to_rrns5_sfixed(sfixed2_n6(3*n+1-binary1 downto -binary1), n);
                    sfxrrns_n6_2 := to_rrns5_sfixed(sfixed3_n6(3*n+1-binary2 downto -binary2), n);


                    sfxrrns_n6_3 := sfxrrns_n6 * sfxrrns_n6_2;

                    check(sfixed1_n6 = to_sfixed(sfxrrns_n6_3, sfixed1_n6'high, sfixed1_n6'low));

                end loop;

            elsif run("test_reverse_conversion_full_redundant_range_n6") then

                n := 6;

                for i in 0 to rrns5RedundantRange(rrns_n6)-1 loop
                    rrns_n6 := to_rrns5_unsigned(to_unsigned(i, 3*n+2), n);
                    binary1 := to_integer(to_unsigned(rrns_n6, 3*n+2));

                    check(i = binary1, "Correct Number " & to_string(i) & " != " & to_string(binary1));
                end loop;

            elsif run("test_reverse_conversion_full_redundant_range_n6_signed") then

                n := 6;

                for i in -rrns5RedundantRange(rrns_n6)/2 to rrns5RedundantRange(rrns_n6)/2 - 1 loop
                    srrns_n6 := to_rrns5_signed(to_signed(i, 3*n+2), n);
                    signed1 := to_integer(to_signed(srrns_n6, 3*n+2));

                    check(i = signed1, "Correct Number " & to_string(i) & " != " & to_string(signed1));
                end loop;

            elsif run("test_reverse_conversion_full_redundant_range_n6_signed_fixedpoint") then

                n := 6;

                for i in -rrns5RedundantRange(rrns_n6)/2 to rrns5RedundantRange(rrns_n6)/2 - 1 loop

                    for commapos in 0 to 3*n+1 loop

                        sfixed1_n6 := to_sfixed(to_signed(i, 3*n+2), sfixed1_n6);
                        sfixed1_n6 := shift_right(sfixed1_n6, commapos);

                        sfxrrns_n6 := to_rrns5_sfixed(sfixed1_n6(sfixed1_n6'high - commapos downto -(commapos)), n);
                        sfixed2_n6 := to_sfixed(sfxrrns_n6, sfixed2_n6'high, sfixed2_n6'low);

                        check(sfixed1_n6 = sfixed2_n6, "Correct Number " & to_string(i) & " comma shift: " & to_string(commapos) &
                         " In sfixed: " & to_string(sfixed1_n6) & " != " & to_string(sfixed2_n6));

                    end loop;

                end loop;

            elsif run("test_no_error_detection_full_redundant_range_n6") then

                n := 6;

                for i in 0 to rrns5RedundantRange(rrns_n6)-1 loop
                    rrns_n6 := to_rrns5_unsigned(to_unsigned(i, 3*n+2), n);
                    binary1 := to_integer(to_unsigned(rrns_n6, 3*n+2));

                    check(rrns_is_erroneus(rrns_n6, to_unsigned(rrns_n6, 3*n+2)) = '0', "Falsely reported an error");
                end loop;

            elsif run("test_no_error_detection_full_redundant_range_n6_signed") then

                n := 6;

                for i in -rrns5RedundantRange(rrns_n6)/2 to rrns5RedundantRange(rrns_n6)/2 - 1 loop
                    srrns_n6 := to_rrns5_signed(to_signed(i, 3*n+2), n);
                    signed1 := to_integer(to_signed(srrns_n6, 3*n+2));

                    check(rrns_is_erroneus(srrns_n6, to_signed(srrns_n6, 3*n+2)) = '0', "Falsely reported an error");
                end loop;

            elsif run("test_no_error_detection_full_redundant_range_n6_signed_fixedpoint") then

                n := 6;

                for i in -rrns5RedundantRange(rrns_n6)/2 to rrns5RedundantRange(rrns_n6)/2 - 1 loop

                    for commapos in 0 to 3*n+1 loop
                        sfixed1_n6 := to_sfixed(to_signed(i, 3*n+2), sfixed1_n6);
                        sfixed1_n6 := shift_right(sfixed1_n6, commapos);

                        sfxrrns_n6 := to_rrns5_sfixed(sfixed1_n6(sfixed1_n6'high - commapos downto -(commapos)), n);
                        sfixed2_n6 := to_sfixed(sfxrrns_n6, sfixed2_n6'high, sfixed2_n6'low);

                        check(rrns_is_erroneus(sfxrrns_n6, sfixed2_n6(sfixed2_n6'high - commapos downto -(commapos))) = '0', "Falsely reported an error");
                    end loop;

                end loop;

            elsif run("test_one_error_detection_full_redundant_range_n6") then

                n := 6;

                for i in 0 to rrns5RedundantRange(rrns_n6)-1 loop
                    rrns_n6 := to_rrns5_unsigned(to_unsigned(i, 3*n+2), n);
                    binary1 := to_integer(to_unsigned(rrns_n6, 3*n+2));

                    faulty_residue := RV.RandInt(1,5);
                    faulty_bit := RV.RandInt(0,n+1);

                    rrns_n6 := injectError(rrns_n6, faulty_residue, faulty_bit);

                    check(rrns_is_erroneus(rrns_n6, to_unsigned(rrns_n6, 3*n+2)) = '1', "Error not reported!");
                end loop;

            elsif run("test_one_error_detection_full_redundant_range_n6_signed") then

                n := 6;

                for i in -rrns5RedundantRange(rrns_n6)/2 to rrns5RedundantRange(rrns_n6)/2 - 1 loop
                    srrns_n6 := to_rrns5_signed(to_signed(i, 3*n+2), n);
                    signed1 := to_integer(to_signed(srrns_n6, 3*n+2));

                    faulty_residue := RV.RandInt(1,5);
                    faulty_bit := RV.RandInt(0,n+1);

                    srrns_n6 := injectError(srrns_n6, faulty_residue, faulty_bit);

                    check(rrns_is_erroneus(srrns_n6, to_signed(srrns_n6, 3*n+2)) = '1', "Error not reported!");
                end loop;

            end if;

        end loop;

        test_runner_cleanup(runner);
    end process;


end architecture testbench;
