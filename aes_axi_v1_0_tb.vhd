----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/03/2019 09:00:32 AM
-- Design Name: 
-- Module Name: aes_axi_v1_0_tb - Behavioral
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
use IEEE.STD_LOGIC_arith.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity aes_axi_v1_0_tb is
--  Port ( );
end aes_axi_v1_0_tb;

architecture Behavioral of aes_axi_v1_0_tb is

    constant WIDTH_c : integer := 128;
    --AES's core address map
    constant START_REG_ADDR_C : integer := 0;
    constant KEY0_REG_ADDR_C : integer := 4;
    constant KEY1_REG_ADDR_C : integer := 8;
    constant KEY2_REG_ADDR_C : integer := 12;
    constant KEY3_REG_ADDR_C : integer := 16;
    --constant READY_REG_ADDR_C : integer := 20;
    constant DONE_REG_ADDR_C : integer := 20; --24; --change if ready needed
    
    signal clk_s: std_logic;
    
     ------------------- AXI Interfaces signals -------------------
    -- Parameters of Axi-Lite Slave Bus Interface S00_AXI
    constant C_S00_AXI_DATA_WIDTH_c : integer := 32;
    constant C_S00_AXI_ADDR_WIDTH_c : integer := 5;
    
    -- Parameters of Axi-Stream Master Bus Interface M00_AXIS
    constant C_M00_AXIS_TDATA_WIDTH_c   : integer    := 128;
    constant C_M00_AXIS_START_COUNT_c     : integer    := 32;
    
    -- Parameters of Axi-Stream Slave Bus Interface S00_AXIS
    constant C_S00_AXIS_TDATA_WIDTH_c     : integer    := 128;
   
    -- Ports of Axi-Lite Slave Bus Interface S00_AXI
    signal s00_axi_aclk_s       : std_logic := '0';
    signal s00_axi_aresetn_s    : std_logic := '1';
    signal s00_axi_awaddr_s     : std_logic_vector(C_S00_AXI_ADDR_WIDTH_c-1 downto 0) := (others => '0');
    signal s00_axi_awprot_s     : std_logic_vector(2 downto 0) := (others => '0');
    signal s00_axi_awvalid_s    : std_logic := '0';
    signal s00_axi_awready_s    : std_logic := '0';
    signal s00_axi_wdata_s      : std_logic_vector(C_S00_AXI_DATA_WIDTH_c-1 downto 0) := (others => '0');
    signal s00_axi_wstrb_s      : std_logic_vector((C_S00_AXI_DATA_WIDTH_c/8)-1 downto 0) := (others => '0');
    signal s00_axi_wvalid_s     : std_logic := '0';
    signal s00_axi_wready_s     : std_logic := '0';
    signal s00_axi_bresp_s      : std_logic_vector(1 downto 0) := (others => '0');
    signal s00_axi_bvalid_s     : std_logic := '0';
    signal s00_axi_bready_s     : std_logic := '0';
    signal s00_axi_araddr_s     : std_logic_vector(C_S00_AXI_ADDR_WIDTH_c-1 downto 0) := (others => '0');
    signal s00_axi_arprot_s     : std_logic_vector(2 downto 0) := (others => '0');
    signal s00_axi_arvalid_s    : std_logic := '0';
    signal s00_axi_arready_s    : std_logic := '0';
    signal s00_axi_rdata_s      : std_logic_vector(C_S00_AXI_DATA_WIDTH_c-1 downto 0) := (others => '0');
    signal s00_axi_rresp_s      : std_logic_vector(1 downto 0) := (others => '0');
    signal s00_axi_rvalid_s     : std_logic := '0';
    signal s00_axi_rready_s     : std_logic := '0';

    --Ports of Axi-Stream Master Bus Interface 
    signal m00_axis_tvalid_s    : std_logic := '0';
    signal m00_axis_tdata_s     : std_logic_vector(C_M00_AXIS_TDATA_WIDTH_c-1 downto 0) := (others => '0');
    signal m00_axis_tready_s    : std_logic := '0';
    
    --Ports of Axi-Stream Slave Bus Interface 
    signal s00_axis_tvalid_s    : std_logic := '0';
    signal s00_axis_tdata_s     : std_logic_vector(C_S00_AXIS_TDATA_WIDTH_c-1 downto 0) := (others => '0');
    signal s00_axis_tready_s    : std_logic := '0';


begin

     clk_gen: process
     begin
        clk_s <= '0', '1' after 100 ns;
        wait for 200 ns;
    end process;
    
    stimulus_generator: process
    variable axi_read_data_v : std_logic_vector(31 downto 0);
    begin
       -- reset AXI-lite interface. Reset will be 10 clock cycles wide
        s00_axi_aresetn_s <= '0';
        -- wait for 5 falling edges of AXI-lite clock signal
        for i in 1 to 5 loop
            wait until falling_edge(clk_s);
        end loop;
        -- release reset
        s00_axi_aresetn_s <= '1';
        wait until falling_edge(clk_s);
        
        ----------------------------------------------------------------------
         -- Enter key                                                       --
        ----------------------------------------------------------------------
         report "Entering first 32 bits of key!";
         -- Set the value for the first 32 bits of key
         wait until falling_edge(clk_s);
         s00_axi_awaddr_s <= conv_std_logic_vector(KEY0_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_c);
         s00_axi_awvalid_s <= '1';
         s00_axi_wdata_s <= x"2b7e1516";
         s00_axi_wvalid_s <= '1';
         s00_axi_wstrb_s <= "1111";
         s00_axi_bready_s <= '1';
         wait until s00_axi_awready_s = '1';
         wait until s00_axi_awready_s = '0';
         wait until falling_edge(clk_s);
         s00_axi_awaddr_s <= conv_std_logic_vector(0, C_S00_AXI_ADDR_WIDTH_c);
         s00_axi_awvalid_s <= '0';
         s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
         s00_axi_wvalid_s <= '0';
         s00_axi_wstrb_s <= "0000";
         wait until s00_axi_bvalid_s = '0';
         wait until falling_edge(clk_s);
         s00_axi_bready_s <= '0';
         wait until falling_edge(clk_s);
         -- wait for 5 falling edges of AXI-lite clock signal
         for i in 1 to 5 loop
            wait until falling_edge(clk_s);
         end loop;
         
         report "Entering second 32 bits of key!";
         -- Set the value for the second 32 bits of key
         wait until falling_edge(clk_s);
         s00_axi_awaddr_s <= conv_std_logic_vector(KEY1_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_c);
         s00_axi_awvalid_s <= '1';
         s00_axi_wdata_s <= x"28aed2a6";
         s00_axi_wvalid_s <= '1';
         s00_axi_wstrb_s <= "1111";
         s00_axi_bready_s <= '1';
         wait until s00_axi_awready_s = '1';
         wait until s00_axi_awready_s = '0';
         wait until falling_edge(clk_s);
         s00_axi_awaddr_s <= conv_std_logic_vector(0, C_S00_AXI_ADDR_WIDTH_c);
         s00_axi_awvalid_s <= '0';
         s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
         s00_axi_wvalid_s <= '0';
         s00_axi_wstrb_s <= "0000";
         wait until s00_axi_bvalid_s = '0';
         wait until falling_edge(clk_s);
         s00_axi_bready_s <= '0';
         wait until falling_edge(clk_s);
         -- wait for 5 falling edges of AXI-lite clock signal
         for i in 1 to 5 loop
            wait until falling_edge(clk_s);
         end loop;
         
         report "Entering third 32 bits of key!";
         -- Set the value for the third 32 bits of key
         wait until falling_edge(clk_s);
         s00_axi_awaddr_s <= conv_std_logic_vector(KEY2_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_c);
         s00_axi_awvalid_s <= '1';
         s00_axi_wdata_s <= x"abf71588";
         s00_axi_wvalid_s <= '1';
         s00_axi_wstrb_s <= "1111";
         s00_axi_bready_s <= '1';
         wait until s00_axi_awready_s = '1';
         wait until s00_axi_awready_s = '0';
         wait until falling_edge(clk_s);
         s00_axi_awaddr_s <= conv_std_logic_vector(0, C_S00_AXI_ADDR_WIDTH_c);
         s00_axi_awvalid_s <= '0';
         s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
         s00_axi_wvalid_s <= '0';
         s00_axi_wstrb_s <= "0000";
         wait until s00_axi_bvalid_s = '0';
         wait until falling_edge(clk_s);
         s00_axi_bready_s <= '0';
         wait until falling_edge(clk_s);
         -- wait for 5 falling edges of AXI-lite clock signal
         for i in 1 to 5 loop
            wait until falling_edge(clk_s);
         end loop;
        
         report "Entering fourth 32 bits of key!";
         -- Set the value for the fourth 32 bits of key
         wait until falling_edge(clk_s);
         s00_axi_awaddr_s <= conv_std_logic_vector(KEY3_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_c);
         s00_axi_awvalid_s <= '1';
         s00_axi_wdata_s <= x"09cf4f3c";
         s00_axi_wvalid_s <= '1';
         s00_axi_wstrb_s <= "1111";
         s00_axi_bready_s <= '1';
         wait until s00_axi_awready_s = '1';
         wait until s00_axi_awready_s = '0';
         wait until falling_edge(clk_s);
         s00_axi_awaddr_s <= conv_std_logic_vector(0, C_S00_AXI_ADDR_WIDTH_c);
         s00_axi_awvalid_s <= '0';
         s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
         s00_axi_wvalid_s <= '0';
         s00_axi_wstrb_s <= "0000";
         wait until s00_axi_bvalid_s = '0';
         wait until falling_edge(clk_s);
         s00_axi_bready_s <= '0';
         wait until falling_edge(clk_s);
         -- wait for 5 falling edges of AXI-lite clock signal
         for i in 1 to 5 loop
            wait until falling_edge(clk_s);
         end loop;
         
         --Set tvalid and tdata
         s00_axis_tvalid_s <= '1';
         wait until falling_edge(clk_s);
         s00_axis_tdata_s <= x"3243f6a8885a308d313198a2e0370734";

        -----------------------------------------------------------------------------
        -- Start the AES core                                                      --
        -----------------------------------------------------------------------------
        report "Starting the matric multiplication process!";
        -- Set the value start bit (bit 0 in the START register) to 1
        wait until falling_edge(clk_s);
        s00_axi_awaddr_s <= conv_std_logic_vector(START_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_c);
        s00_axi_awvalid_s <= '1';
        s00_axi_wdata_s <= conv_std_logic_vector(1, C_S00_AXI_DATA_WIDTH_c);
        s00_axi_wvalid_s <= '1';
        s00_axi_wstrb_s <= "1111";
        s00_axi_bready_s <= '1';
        wait until s00_axi_awready_s = '1';
        wait until s00_axi_awready_s = '0';
        wait until falling_edge(clk_s);
        s00_axi_awaddr_s <= conv_std_logic_vector(0, C_S00_AXI_ADDR_WIDTH_c);
        s00_axi_awvalid_s <= '0';
        s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
        s00_axi_wvalid_s <= '0';
        s00_axi_wstrb_s <= "0000";
        wait until s00_axi_bvalid_s = '0';
        wait until falling_edge(clk_s);
        s00_axi_bready_s <= '0';
        wait until falling_edge(clk_s);
        
        report "Clearing the start bit!";
        -- Set the value start bit (bit 0 in the CMD register) to 1
        wait until falling_edge(clk_s);
        s00_axi_awaddr_s <= conv_std_logic_vector(START_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_c);
        s00_axi_awvalid_s <= '1';
        s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
        s00_axi_wvalid_s <= '1';
        s00_axi_wstrb_s <= "1111";
        s00_axi_bready_s <= '1';
        wait until s00_axi_awready_s = '1';
        wait until s00_axi_awready_s = '0';
        wait until falling_edge(clk_s);
        s00_axi_awaddr_s <= conv_std_logic_vector(0, C_S00_AXI_ADDR_WIDTH_c);
        s00_axi_awvalid_s <= '0';
        s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
        s00_axi_wvalid_s <= '0';
        s00_axi_wstrb_s <= "0000";
        wait until s00_axi_bvalid_s = '0';
        wait until falling_edge(clk_s);
        s00_axi_bready_s <= '0';
        wait until falling_edge(clk_s); 
        
        --Clear tvalid and tdata
        s00_axis_tvalid_s <= '0';
        s00_axis_tdata_s <= (others => '0');
                
             
        -- wait for 5 falling edges of AXI-lite clock signal
        for i in 1 to 5 loop
            wait until falling_edge(clk_s);
        end loop;
           
        -------------------------------------------------------------------------------------------
        -- Wait until AES core finishes encription                                               --
        -------------------------------------------------------------------------------------------
         report "Waiting for the encription process to complete!";
         loop
             -- Read the content of the DONE register
             wait until falling_edge(clk_s);
             s00_axi_araddr_s <= conv_std_logic_vector(DONE_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_c);
             s00_axi_arvalid_s <= '1';
             s00_axi_rready_s <= '1';
             wait until s00_axi_arready_s = '1';
             axi_read_data_v := s00_axi_rdata_s;
             wait until s00_axi_arready_s = '0';
             wait until falling_edge(clk_s);
             s00_axi_araddr_s <= conv_std_logic_vector(0, 5);
             s00_axi_arvalid_s <= '0';
             s00_axi_rready_s <= '0';
            
             -- Check if is the 1st bit of the DONE register set to one
             if (axi_read_data_v(0) = '1') then
                 -- AES encription process completed
                 exit;
             else
                wait for 1000 ns;
             end if;
         end loop;
         
         -------------------------------------------------------------------------------------------
         -- Read the elements of matrix C from the Matrix Multiplier core                         --
         -------------------------------------------------------------------------------------------
          report "The results of the encription!";
          m00_axis_tready_s <= '1'; 
 
          -- wait for 5 falling edges of AXI-lite clock signal
          for i in 1 to 5 loop
              wait until falling_edge(clk_s);
          end loop;
          m00_axis_tready_s <= '0'; 
          
         
        -- End of the test
        wait;
        
    end process;
    
    -------------------------------------------------------------------------
    --                             DUT                                     --
    -------------------------------------------------------------------------
    aes_axi : entity work.aes_axi_v1_0(arch_imp)
        generic map(
                WIDTH => WIDTH_c
        )
        port map (
        -- Ports of Axi Slave Bus Interface S00_AXI
        s00_axi_aclk        => clk_s,
        s00_axi_aresetn     => s00_axi_aresetn_s,
        s00_axi_awaddr      => s00_axi_awaddr_s,
        s00_axi_awprot      => s00_axi_awprot_s, 
        s00_axi_awvalid     => s00_axi_awvalid_s,
        s00_axi_awready     => s00_axi_awready_s,
        s00_axi_wdata       => s00_axi_wdata_s,
        s00_axi_wstrb       => s00_axi_wstrb_s,
        s00_axi_wvalid      => s00_axi_wvalid_s,
        s00_axi_wready      => s00_axi_wready_s,
        s00_axi_bresp       => s00_axi_bresp_s,
        s00_axi_bvalid      => s00_axi_bvalid_s,
        s00_axi_bready      => s00_axi_bready_s,
        s00_axi_araddr      => s00_axi_araddr_s,
        s00_axi_arprot      => s00_axi_arprot_s,
        s00_axi_arvalid     => s00_axi_arvalid_s,
        s00_axi_arready     => s00_axi_arready_s,
        s00_axi_rdata       => s00_axi_rdata_s,
        s00_axi_rresp       => s00_axi_rresp_s,
        s00_axi_rvalid      => s00_axi_rvalid_s,
        s00_axi_rready      => s00_axi_rready_s,
        
        --Ports of Axi-Stream Master Bus Interface 
        m00_axis_tvalid     => m00_axis_tvalid_s,
        m00_axis_tdata      => m00_axis_tdata_s,
        m00_axis_tready     => m00_axis_tready_s,
        
        --Ports of Axi-Stream Slave Bus Interface 
        s00_axis_tvalid     => s00_axis_tvalid_s,
        s00_axis_tdata      => s00_axis_tdata_s,
        s00_axis_tready     => s00_axis_tready_s
        
        );
    
end Behavioral;
