----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/26/2019 04:37:29 PM
-- Design Name: 
-- Module Name: aes_tb - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity aes_tb is
--  Port ( );
end aes_tb;

architecture Behavioral of aes_tb is
    signal clk_s        : STD_LOGIC := '0';
    signal reset_s      : STD_LOGIC := '1';
    signal start_s      : STD_LOGIC := '0';
    signal key_s        : STD_LOGIC_VECTOR(127 downto 0) := (others => '0');
    signal plaintext_s  : STD_LOGIC_VECTOR(127 downto 0):= (others => '0');
    signal ready_s      : STD_LOGIC := '0';
    signal data_valid_s : STD_LOGIC := '0';        
    signal ciphertext_s : STD_LOGIC_VECTOR(127 downto 0) := (others => '0');
begin
    dut: entity work.aes(Behavioral)
    port map(
        pi_clk        =>  clk_s,
        pi_reset      =>  reset_s,
        pi_start      =>  start_s,
        pi_key        =>  key_s,
        pi_plaintext  =>  plaintext_s,
        po_ready      =>  ready_s,
        po_data_valid =>  data_valid_s,        
        po_ciphertext =>  ciphertext_s);
    clk_gen: process
    begin
        wait for 50 ns;
        clk_s <= not clk_s;
    end process;
    
    stim_gen: process
    begin
        key_s <= X"2b7e151628aed2a6abf7158809cf4f3c";
        plaintext_s <= X"3243f6a8885a308d313198a2e0370734";
        reset_s <= '1';
        wait for 100 ns;
        reset_s <= '0';
        wait for 100 ns;
        wait until falling_edge(clk_s);
        start_s <= '1';
        wait until ready_s = '1';
        start_s <= '0';
        wait;
    end process;
    
end Behavioral;
