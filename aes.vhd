----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Srdjan Skala
-- 
-- Create Date: 04/02/2019 07:15:18 PM
-- Design Name: 
-- Module Name: aes - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity aes is
    generic(
        WIDTH : natural := 128;
        Nr    : natural := 10;
        Nb    : natural := 4;
        Nk    : natural := 4;
        BYTE  : natural := 8);
    port( 
        pi_clk        : in STD_LOGIC;
        pi_reset      : in STD_LOGIC;
        pi_start      : in STD_LOGIC;
        pi_key        : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
        pi_plaintext  : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
        --po_ready      : out STD_LOGIC;    --add if needed
        pi_tready     : in STD_LOGIC;
        pi_tvalid     : in STD_LOGIC;
        po_tvalid     : out STD_LOGIC;
        po_tready     : out STD_LOGIC;
        po_done       : out STD_LOGIC;        
        po_ciphertext : out STD_LOGIC_VECTOR(WIDTH-1 downto 0));
end aes;

architecture Behavioral of aes is
    type state_type is (idle, key_extension1, key_extension2, key_extension3, key_extension4, key_extension5, key_extension6, add_round_key_0_1, add_round_key_0_2, add_round_key_0_3,
                        sub_bytes1, sub_bytes2, sub_bytes3, sub_bytes4, shift_rows, mix_columns1, mix_columns2, add_round_key_round_1, 
                        add_round_key_round_2, add_round_key_round_3, check_round);
    type rkey_coef_t is array (0 to 175) of std_logic_vector(BYTE-1 downto 0);                      
    type sbox_coef_t is array (0 to 255) of std_logic_vector(BYTE-1 downto 0);
    type rcon_coef_t is array (0 to 31) of std_logic_vector(BYTE-1 downto 0);
    type tmp_coef_t is array  (0 to 3) of std_logic_vector(BYTE-1 downto 0);
    type coef_t  is array (0 to 15) of std_logic_vector(BYTE-1 downto 0); 
    
    signal sbox : sbox_coef_t := (
        --    0    1     2      3     4    5      6     7     8     9    A      B     C     D     E     F
            X"63", X"7c", X"77", X"7b", X"f2", X"6b", X"6f", X"c5", X"30", X"01", X"67", X"2b", X"fe", X"d7", X"ab", X"76", --0
    
            X"ca", X"82", X"c9", X"7d", X"fa", X"59", X"47", X"f0", X"ad", X"d4", X"a2", X"af", X"9c", X"a4", X"72", X"c0", --1
    
            X"b7", X"fd", X"93", X"26", X"36", X"3f", X"f7", X"cc", X"34", X"a5", X"e5", X"f1", X"71", X"d8", X"31", X"15", --2
    
            X"04", X"c7", X"23", X"c3", X"18", X"96", X"05", X"9a", X"07", X"12", X"80", X"e2", X"eb", X"27", X"b2", X"75", --3
    
            X"09", X"83", X"2c", X"1a", X"1b", X"6e", X"5a", X"a0", X"52", X"3b", X"d6", X"b3", X"29", X"e3", X"2f", X"84", --4
    
            X"53", X"d1", X"00", X"ed", X"20", X"fc", X"b1", X"5b", X"6a", X"cb", X"be", X"39", X"4a", X"4c", X"58", X"cf", --5
    
            X"d0", X"ef", X"aa", X"fb", X"43", X"4d", X"33", X"85", X"45", X"f9", X"02", X"7f", X"50", X"3c", X"9f", X"a8", --6
    
            X"51", X"a3", X"40", X"8f", X"92", X"9d", X"38", X"f5", X"bc", X"b6", X"da", X"21", X"10", X"ff", X"f3", X"d2", --7
    
            X"cd", X"0c", X"13", X"ec", X"5f", X"97", X"44", X"17", X"c4", X"a7", X"7e", X"3d", X"64", X"5d", X"19", X"73", --8
    
            X"60", X"81", X"4f", X"dc", X"22", X"2a", X"90", X"88", X"46", X"ee", X"b8", X"14", X"de", X"5e", X"0b", X"db", --9
    
            X"e0", X"32", X"3a", X"0a", X"49", X"06", X"24", X"5c", X"c2", X"d3", X"ac", X"62", X"91", X"95", X"e4", X"79", --A
    
            X"e7", X"c8", X"37", X"6d", X"8d", X"d5", X"4e", X"a9", X"6c", X"56", X"f4", X"ea", X"65", X"7a", X"ae", X"08", --B
    
            X"ba", X"78", X"25", X"2e", X"1c", X"a6", X"b4", X"c6", X"e8", X"dd", X"74", X"1f", X"4b", X"bd", X"8b", X"8a", --C
    
            X"70", X"3e", X"b5", X"66", X"48", X"03", X"f6", X"0e", X"61", X"35", X"57", X"b9", X"86", X"c1", X"1d", X"9e", --D
    
            X"e1", X"f8", X"98", X"11", X"69", X"d9", X"8e", X"94", X"9b", X"1e", X"87", X"e9", X"ce", X"55", X"28", X"df", --E
    
            X"8c", X"a1", X"89", X"0d", X"bf", X"e6", X"42", X"68", X"41", X"99", X"2d", X"0f", X"b0", X"54", X"bb", X"16" ); --F
            
    signal rcon : rcon_coef_t := (
            X"8d", X"01", X"02", X"04", X"08", X"10", X"20", X"40", X"80", X"1b", X"36", X"6c", X"d8", X"ab", X"4d", X"9a",
    
            X"2f", X"5e", X"bc", X"63", X"c6", X"97", X"35", X"6a", X"d4", X"b3", X"7d", X"fa", X"ef", X"c5", X"91", X"39"); 
          
    signal state_reg, state_next: state_type;
    signal roundKey_reg, roundKey_next : rkey_coef_t;
    signal j_reg, j_next : std_logic_vector (2 downto 0);
    signal i_reg, i_next : std_logic_vector (5 downto 0);
    signal round_reg, round_next : std_logic_vector(4 downto 0);
    signal tmp_reg, tmp_next : tmp_coef_t;
    signal t_reg, t_next, temp_reg, temp_next : std_logic_vector(BYTE-1 downto 0);
    signal first_reg, first_next: std_logic;
    signal done_reg, done_next : std_logic;
    signal key_next, key_reg, new_plaintext_reg, new_plaintext_next : coef_t ; 
 
    
    constant CONST_TMP: std_logic_vector(7 downto 0):="00011011";
            
begin


    -- control path: state register
    process (pi_clk)
    begin
        if (pi_clk'event and pi_clk = '1') then
            if pi_reset = '1' then
                   state_reg <= idle;
             else
                state_reg <= state_next;
             end if;
        end if;
    end process; 
    
    -- control path: next-state/output logic
    process (state_reg, pi_start, j_reg, i_reg, round_reg, first_reg, pi_tvalid)
    begin
        case state_reg is
            when idle =>
               if(pi_start = '1') then
                   if(first_reg = '1' and pi_tvalid = '1') then
                        state_next <= key_extension1;
                   elsif (pi_tvalid = '1') then
                        state_next <= add_round_key_0_1;
                   else
                        state_next <= idle;
                   end if;
               else
                    state_next <= idle;
               end if;
            when key_extension1 =>
                if(to_integer(unsigned(i_reg)) = Nk-1) then 
                    state_next <= key_extension2;
                else
                    state_next <= key_extension1; 
                end if;
            when key_extension2 =>
                state_next <= key_extension3;
            when key_extension3 => 
                if (to_integer(unsigned(j_reg)) = 3)then
                    if(i_reg(1 downto 0) = "00" ) then 
                        state_next <= key_extension4;
                    else
                        state_next <= key_extension6;
                    end if;
                else 
                    state_next <= key_extension3;
                end if;
            when key_extension4 =>
                state_next <= key_extension5;
            when key_extension5 =>
                state_next <= key_extension6;
            when key_extension6 =>
                if(to_integer(unsigned(i_reg)) = (Nb*(Nr+1)-1)) then --44 in decimal
                    state_next <= add_round_key_0_1;
                else
                    state_next <= key_extension2; 
                end if;
            when add_round_key_0_1 =>
                state_next <= add_round_key_0_2;
            when add_round_key_0_2 =>
                if(to_integer(unsigned(j_reg)) = 3) then
                    state_next <= add_round_key_0_3;
                else 
                    state_next <= add_round_key_0_2;
                end if;
            when add_round_key_0_3 =>
                if(to_integer(unsigned(i_reg)) = 3) then
                    state_next <= sub_bytes1;
                else
                    state_next <= add_round_key_0_1;
                end if;
            when sub_bytes1 =>
                state_next <= sub_bytes2;
            when sub_bytes2 =>
                state_next <= sub_bytes3;
            when sub_bytes3 =>
                if(to_integer(unsigned(j_reg)) = 3) then
                    state_next <= sub_bytes4;
                else
                    state_next <= sub_bytes3;
                end if;
            when sub_bytes4 =>
                if(to_integer(unsigned(i_reg)) = 3) then
                    state_next <= shift_rows;
                else
                    state_next <= sub_bytes2;
                end if;
            when shift_rows =>
                if(to_integer(unsigned(round_reg)) = Nr) then
                    state_next <= add_round_key_round_1;
                else
                    state_next <= mix_columns1;
                end if;
            when mix_columns1 =>
                state_next <= mix_columns2;
            when mix_columns2 =>

                if(to_integer(unsigned(i_reg)) = 3) then
                    state_next <= add_round_key_round_1;
                else 
                    state_next <= mix_columns1;
                end if;
            when add_round_key_round_1 =>
                state_next <= add_round_key_round_2;
            when add_round_key_round_2 =>
                if(to_integer(unsigned(j_reg)) = 3) then
                    state_next <= add_round_key_round_3;
                else
                    state_next <= add_round_key_round_2;  
                end if;
            when add_round_key_round_3 =>
                if(to_integer(unsigned(i_reg)) = 3) then
                    state_next <= check_round;
                else
                    state_next <= add_round_key_round_1;
                end if;
            when check_round =>
                if(to_integer(unsigned(round_reg)) = Nr) then
                    state_next <= idle;
                else 
                    state_next <= sub_bytes1;
                end if;
               
        end case;        
    end process;

    -- control path: output logic
    po_tready <= '1' when (state_reg = idle and pi_start ='1') else '0';
    --po_ready <= '1' when state_reg = idle else '0';

    --data path: data register
    process (pi_clk, pi_reset)
    begin
        
       if(pi_clk'event and pi_clk = '1') then
            if(pi_reset = '1') then
                   i_reg <= (others => '0');
                   j_reg <= (others => '0');
                   round_reg <= (others => '0');
                   for i in 0 to 15 loop
                       new_plaintext_reg(i) <= (others => '0');
                       key_reg(i) <= (others => '0');
                   end loop;
                   t_reg <= (others => '0');
                   temp_reg <= (others => '0');
                   for i in 0 to 3 loop
                       tmp_reg(i) <= (others => '0');
                   end loop;
                   for i in 0 to 175 loop
                       roundKey_reg(i) <= (others => '0');
                   end loop;
                   first_reg <= '1';
                   done_reg <= '0';
            else  
                i_reg <= i_next;
                j_reg <= j_next;
                round_reg <= round_next;
                key_reg <= key_next;
                new_plaintext_reg <= new_plaintext_next;
                t_reg <= t_next;
                temp_reg <= temp_next;
                tmp_reg <= tmp_next; 
                roundKey_reg <= roundKey_next;
                first_reg <= first_next;
                done_reg <= done_next;
            end if;
        end if;
    end process;
    
    -- datapath: routing multiplexer
    process(i_reg, j_reg, round_reg,  pi_tvalid,t_reg, temp_reg, tmp_reg, roundKey_reg, key_reg, new_plaintext_reg, pi_key, pi_start, first_reg, state_reg, pi_plaintext, done_reg)
    begin
        i_next <= i_reg;
        j_next <= j_reg;
        round_next <= round_reg;
        new_plaintext_next <= new_plaintext_reg;
        key_next <= key_reg;
        t_next <= t_reg;
        tmp_next <= tmp_reg; 
        temp_next <= temp_reg;
        roundKey_next <= roundKey_reg;
        first_next <= first_reg;
        done_next <= done_reg;
        case state_reg is
            when idle =>
                if(pi_start = '1') then
                    if(first_reg = '1') then
                        for i in 0 to 15 loop
                            key_next(15-i)(7 downto 0) <= pi_key((i*8+7) downto (8*i)); 
                        end loop;
                    end if;
                    if (pi_tvalid = '1') then
                        for i in 0 to 15 loop
                            new_plaintext_next(15-i)(7 downto 0) <= pi_plaintext((i*8+7) downto (8*i));
                        end loop;
                    end if;                
                    i_next <= (others => '0');
                    round_next <= (others => '0');
                    done_next <= '0';
                end if;
            when key_extension1 =>
                 roundKey_next((to_integer(unsigned(i_reg)))*4) <= key_reg((to_integer(unsigned(i_reg)))*4);
                 roundKey_next((to_integer(unsigned(i_reg)))*4+1) <= key_reg((to_integer(unsigned(i_reg)))*4+1);
                 roundKey_next((to_integer(unsigned(i_reg)))*4+2) <= key_reg((to_integer(unsigned(i_reg)))*4+2);
                 roundKey_next((to_integer(unsigned(i_reg)))*4+3) <= key_reg((to_integer(unsigned(i_reg)))*4+3);
                 i_next <= (std_logic_vector(unsigned(i_reg) + 1));
            when key_extension2 =>
                 j_next <= (others => '0');
            when key_extension3 =>   
                 tmp_next(to_integer(unsigned(j_reg))) <= roundKey_reg(((to_integer(unsigned(i_reg)))-1)*4 + (to_integer(unsigned(j_reg))));
                 j_next <= (std_logic_vector(unsigned(j_reg) + 1));
            when key_extension4 =>
                 tmp_next(0) <= sbox(to_integer(unsigned(tmp_reg(1)))); 
                 tmp_next(1) <= sbox(to_integer(unsigned(tmp_reg(2)))); 
                 tmp_next(2) <= sbox(to_integer(unsigned(tmp_reg(3)))); 
                 tmp_next(3) <= sbox(to_integer(unsigned(tmp_reg(0)))); 
            when key_extension5 =>
                 tmp_next(0) <= tmp_reg(0) xor rcon(to_integer(unsigned(std_logic_vector'("00" & i_reg(5 downto 2))))); 
            when key_extension6 =>
                 roundKey_next((to_integer(unsigned(i_reg)))*4) <= roundKey_reg(((to_integer(unsigned(i_reg)))-Nk)*4) xor tmp_reg(0);
                 roundKey_next((to_integer(unsigned(i_reg)))*4+1) <= roundKey_reg(((to_integer(unsigned(i_reg)))-Nk)*4+1) xor tmp_reg(1); 
                 roundKey_next((to_integer(unsigned(i_reg)))*4+2) <= roundKey_reg(((to_integer(unsigned(i_reg)))-Nk)*4+2) xor tmp_reg(2);
                 roundKey_next((to_integer(unsigned(i_reg)))*4+3) <= roundKey_reg(((to_integer(unsigned(i_reg)))-Nk)*4+3) xor tmp_reg(3);
                 if(to_integer(unsigned(i_reg)) = (Nb*(Nr+1)-1)) then --43 in decimal
                    i_next <= (others => '0');
                 else
                    i_next <= (std_logic_vector(unsigned(i_reg)+1));
                 end if;
            when add_round_key_0_1 =>
                 j_next <= (others => '0');
            when add_round_key_0_2 =>
                 new_plaintext_next((to_integer(unsigned(i_reg)))*4+(to_integer(unsigned(j_reg)))) <= new_plaintext_reg((to_integer(unsigned(i_reg)))*4+(to_integer(unsigned(j_reg)))) xor  roundKey_reg((to_integer(unsigned(round_reg)))*Nb*4+(to_integer(unsigned(i_reg)))*Nb+(to_integer(unsigned(j_reg))));
                 j_next <= (std_logic_vector(unsigned(j_reg) + 1));
            when add_round_key_0_3 =>
                 i_next <= (std_logic_vector(unsigned(i_reg) + 1));
                 if(to_integer(unsigned(i_reg)) = 3) then
                     round_next <= "00001";
                 end if;
            when sub_bytes1 =>
                 i_next <= (others => '0');
            when sub_bytes2 =>
                 j_next <= (others => '0');
            when sub_bytes3 =>
                 new_plaintext_next((to_integer(unsigned(i_reg)))*4+(to_integer(unsigned(j_reg)))) <=  sbox(to_integer(unsigned(new_plaintext_reg((to_integer(unsigned(i_reg)))*4+(to_integer(unsigned(j_reg))))))); -- missing getSbox
                 j_next <= (std_logic_vector(unsigned(j_reg) + 1));
            when sub_bytes4 =>
                 i_next <= (std_logic_vector(unsigned(i_reg) + 1));
            when shift_rows =>
                 --second row
                 new_plaintext_next(1) <= new_plaintext_reg(5);
                 new_plaintext_next(5) <= new_plaintext_reg(9);
                 new_plaintext_next(9) <= new_plaintext_reg(13);
                 new_plaintext_next(13) <= new_plaintext_reg(1);
                 --third row
                 new_plaintext_next(2) <= new_plaintext_reg(10);
                 new_plaintext_next(6) <= new_plaintext_reg(14);
                 new_plaintext_next(10) <= new_plaintext_reg(2);
                 new_plaintext_next(14) <= new_plaintext_reg(6); 
                 --fourth row
                 new_plaintext_next(3) <= new_plaintext_reg(15);
                 new_plaintext_next(7) <= new_plaintext_reg(3);
                 new_plaintext_next(11) <= new_plaintext_reg(7);
                 new_plaintext_next(15) <= new_plaintext_reg(11);
                 i_next <= (others => '0');
                 j_next <= (others => '0');
            when mix_columns1 =>
                  t_next <= new_plaintext_reg((to_integer(unsigned(i_reg)))*4);
                  temp_next <= new_plaintext_reg(((to_integer(unsigned(i_reg)))*4)) xor new_plaintext_reg(((to_integer(unsigned(i_reg)))*4)+1) xor new_plaintext_reg(((to_integer(unsigned(i_reg)))*4)+2) xor new_plaintext_reg(((to_integer(unsigned(i_reg)))*4)+3);
            when mix_columns2 =>
                   new_plaintext_next((to_integer(unsigned(i_reg)))*4) <= ((new_plaintext_reg((to_integer(unsigned(i_reg)))*4)(6 downto 0) xor new_plaintext_reg((to_integer(unsigned(i_reg)))*4+1)(6 downto 0)) & '0') xor (std_logic_vector(resize((shift_right(unsigned(new_plaintext_reg((to_integer(unsigned(i_reg)))*4) xor new_plaintext_reg((to_integer(unsigned(i_reg)))*4+1)), 7) * unsigned(CONST_TMP)), 8))) xor temp_reg xor new_plaintext_reg((to_integer(unsigned(i_reg)))*4);
                   new_plaintext_next(((to_integer(unsigned(i_reg)))*4)+1) <= ((new_plaintext_reg((to_integer(unsigned(i_reg)))*4+1)(6 downto 0) xor new_plaintext_reg((to_integer(unsigned(i_reg)))*4+2)(6 downto 0)) & '0') xor (std_logic_vector(resize((shift_right(unsigned(new_plaintext_reg((to_integer(unsigned(i_reg)))*4+1) xor new_plaintext_reg((to_integer(unsigned(i_reg)))*4+2)), 7) * unsigned(CONST_TMP)), 8))) xor temp_reg xor new_plaintext_reg(((to_integer(unsigned(i_reg)))*4)+1);
                   new_plaintext_next(((to_integer(unsigned(i_reg)))*4)+2) <= ((new_plaintext_reg((to_integer(unsigned(i_reg)))*4+2) (6 downto 0) xor new_plaintext_reg((to_integer(unsigned(i_reg)))*4+3)(6 downto 0)) & '0') xor (std_logic_vector(resize((shift_right(unsigned(new_plaintext_reg((to_integer(unsigned(i_reg)))*4+2) xor new_plaintext_reg((to_integer(unsigned(i_reg)))*4+3)), 7) * unsigned(CONST_TMP)), 8))) xor temp_reg xor new_plaintext_reg(((to_integer(unsigned(i_reg)))*4)+2);
                   new_plaintext_next(((to_integer(unsigned(i_reg)))*4)+3) <= ((new_plaintext_reg((to_integer(unsigned(i_reg)))*4+3) (6 downto 0) xor t_reg(6 downto 0)) & '0') xor (std_logic_vector(resize((shift_right(unsigned(new_plaintext_reg((to_integer(unsigned(i_reg)))*4+3) xor t_reg), 7) * unsigned(CONST_TMP)), 8))) xor temp_reg xor new_plaintext_reg(((to_integer(unsigned(i_reg)))*4)+3);
                   if(to_integer(unsigned(i_reg)) = 3) then
                        i_next <= (others => '0');
                  else 
                        i_next <= (std_logic_vector(unsigned(i_reg) + 1));
                 end if;
            when add_round_key_round_1 =>
                 j_next <= (others => '0');
            when add_round_key_round_2 =>
                 new_plaintext_next((to_integer(unsigned(i_reg)))*4+(to_integer(unsigned(j_reg)))) <= new_plaintext_reg((to_integer(unsigned(i_reg)))*4+(to_integer(unsigned(j_reg)))) xor  roundKey_reg((to_integer(unsigned(round_reg)))*Nb*4+(to_integer(unsigned(i_reg)))*Nb+(to_integer(unsigned(j_reg))));
                 j_next <= (std_logic_vector(unsigned(j_reg) + 1));
            when add_round_key_round_3 =>
                 i_next <= (std_logic_vector(unsigned(i_reg) + 1));
            when check_round =>
                 round_next <= (std_logic_vector(unsigned(round_reg)+1));
                 if(to_integer(unsigned(round_reg)) = Nr) then
                    i_next <= (others => '0');
                    first_next <= '0';
                    round_next <= "00000";
                    done_next <= '1';
                 end if;
            when others =>                              
        end case;    
        
    end process;
  

    --datapath: output
    po_done <= '1' when done_reg = '1' else '0';
    
    process (pi_tready, new_plaintext_reg, done_reg) is
    begin
        if(pi_tready = '1' and done_reg = '1') then
                po_tvalid <= '1';
                po_ciphertext <= new_plaintext_reg(0) & new_plaintext_reg(1) & new_plaintext_reg(2) & new_plaintext_reg(3) & new_plaintext_reg(4) & new_plaintext_reg(5) & new_plaintext_reg(6) & new_plaintext_reg(7)
                               & new_plaintext_reg(8) & new_plaintext_reg(9) & new_plaintext_reg(10) & new_plaintext_reg(11) & new_plaintext_reg(12) & new_plaintext_reg(13) 
                               & new_plaintext_reg(14) & new_plaintext_reg(15);
        else
            po_tvalid <= '0';
            po_ciphertext <= (others => '0');
        end if;
    end process;


end Behavioral;
