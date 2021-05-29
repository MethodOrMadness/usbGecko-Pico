 -- newexi.vhd
--------------------------------------------------------------------------------
--
-- File: usbexi.vhd
-- Version: 0.1 Start date 01/07/2010
--
-- Description: 
--
-- USB EXI
--
-- Targeted device: Proasic3  AP3125
-- Author: Ian Callaghan
--
--------------------------------------------------------------------------------
-- library definitions
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
--library synplify;
--use synplify.attributes.all;

-- Main entity
entity usbexi is
port (
-- USB
    usb_txe : in std_logic;
    usb_rxf : in std_logic;
    usb_pwren : in std_logic;
    usb_rd : out std_logic;
    usb_wr : out std_logic;
    usb_data : inout std_logic_vector(7 downto 0);
-- Wii
    exi_cs : in std_logic;
    exi_clk : in std_logic;
    exi_do : in std_logic;
    exi_di : out std_logic
);

end usbexi;

architecture arch_usbexi of usbexi is
attribute syn_black_box : boolean;
attribute syn_encoding : string;

subtype bit8 is integer range 0 to 255;

signal reset_conf : std_logic;
signal usb_read_mode_set : std_logic;
signal usb_write_mode_set : std_logic;
signal id_mode_set : std_logic;
signal usb_tx_status_set : std_logic;
signal usb_rx_status_set : std_logic;

signal exi_usb_data_in : std_logic_vector(7 downto 0);
signal exi_read_buffer : std_logic_vector(7 downto 0);
signal exi_count : bit8;
signal exi_cmd : std_logic_vector(3 downto 0);


----------------------------------------------------------------
begin
----------------------------------------------------------------
    
    
    reset_conf <= not usb_pwren; -- pwren is high during suspend, low once configured
                                 -- so we flip it to have reset_conf = 0 for suspend
    

----------------------------------------------------------------
-- Main State Machine
----------------------------------------------------------------

process (exi_clk, exi_cs, reset_conf)

begin
    if(exi_cs = '1' or reset_conf = '0') then
        exi_count <= 0;
        exi_usb_data_in <= (others => '0');
        exi_read_buffer <= (others => '0');
        exi_cmd <= (others => '0');
        usb_rd <= '1';
        usb_wr <= '0';
        usb_read_mode_set <= '0';
        usb_write_mode_set <= '0';
        usb_tx_status_set <= '0';
        usb_rx_status_set <= '0';
        id_mode_set <= '0';
        usb_data(7 downto 0) <= (others => 'Z'); -- best to put here for suspend reasons

    elsif (exi_clk'event and exi_clk ='1') then
        
        case exi_count is
            when 0 =>            
                exi_cmd(3) <= exi_do;
                exi_di <= '0';
            when 1 =>
                exi_cmd(2) <= exi_do;
                exi_di <= '0';
            when 2 =>
                exi_cmd(1) <= exi_do;
                exi_di <= '0';
            when 3 =>
                exi_cmd(0) <= exi_do;
                if(exi_cmd = x"A") then	-- 'A' receive byte from PC
				    if(usb_rxf = '0') then                  -- are we read to read?
                        exi_di <= '1';                      -- ok tell the wii
                        usb_read_mode_set <= '1';
                        usb_rd <= '0';                      -- send RD low  
                    end if;     
                elsif(exi_cmd = x"E") then	-- 'E' send / receive
                    if(usb_rxf = '0') then                  -- are we read to read?
                        exi_di <= '1';                      -- ok tell the wii,but dont set mode
                        usb_read_mode_set <= '1';
                        usb_rd <= '0';                      -- send RD low 
                    end if;   
                 end if; 
                 
            when 4 =>
                exi_read_buffer(7) <= exi_do;
                if(usb_read_mode_set = '1') then
                   exi_di <= '0';                           -- clear
                end if;
                      
                if(exi_cmd = x"B") then	-- 'B' send byte to PC
				    if(usb_txe = '0') then                 -- can we write?
                        exi_di <= '1';                      -- ok tell the wii
                        usb_write_mode_set <= '1';
                    end if;
                elsif(exi_cmd = x"C") then	-- 'C' check TX status
                    if(usb_txe = '0') then                 -- can we write?
                        exi_di <= '1';                      -- ok tell the wii
                        usb_tx_status_set <= '1';
                    end if;
                elsif(exi_cmd = x"9") then	-- '9' ID
                    id_mode_set <= '1';
                    exi_di <= '1';    -- 1
                elsif(exi_cmd = x"D") then	-- '6' receive rx status
                    if(usb_rxf = '0') then                  -- are we read to read?
                        exi_di <= '1';                      -- ok tell the wii,but dont set mode
                        usb_rx_status_set <= '1';
                    end if;  
                elsif(exi_cmd = x"E") then	-- 'E' send / receive
                    if(usb_txe = '0') then                  -- are we read to read?
                        exi_di <= '1';                      -- ok tell the wii,but dont set mode
                        usb_write_mode_set <= '1';
                    end if; 
                end if;
                
            when 5 =>                                  -- get data here
                exi_read_buffer(6) <= exi_do;
                if(usb_read_mode_set = '1') then
                    exi_usb_data_in(7 downto 0) <= usb_data(7 downto 0);
                end if;
                
                if(usb_write_mode_set = '1' or usb_tx_status_set = '1' or usb_rx_status_set = '1') then
                   exi_di <= '0';                           -- clear
                end if;

                if(id_mode_set = '1') then
                    exi_di <= '0'; -- 2
                end if;

            when 6 =>
                exi_read_buffer(5) <= exi_do;
                if(usb_read_mode_set = '1') then
                   usb_rd <= '1';                           
                end if;

                if(id_mode_set = '1') then
                    exi_di <= '0'; -- 3
                end if;

            when 7 =>
                exi_read_buffer(4) <= exi_do;
                if(usb_read_mode_set = '1') then
                   exi_di <= exi_usb_data_in(7);
                end if;

                if(id_mode_set = '1') then
                    exi_di <= '0'; -- 4
                end if;


            when 8 =>   
                exi_read_buffer(3) <= exi_do;
                if(usb_read_mode_set = '1') then
                   exi_di <= exi_usb_data_in(6);
                end if;

                 if(id_mode_set = '1') then
                    exi_di <= '1'; -- 5
                end if;
                
            
            when 9 =>
                exi_read_buffer(2) <= exi_do;
                if(usb_read_mode_set = '1') then
                   exi_di <= exi_usb_data_in(5);
                end if;

                 if(id_mode_set = '1') then
                    exi_di <= '1'; -- 6
                end if;
                

            
            when 10 => 
                exi_read_buffer(1) <= exi_do;
                if(usb_read_mode_set = '1') then
                   exi_di <= exi_usb_data_in(4);
                end if;

                 if(id_mode_set = '1') then
                    exi_di <= '1'; -- 7
                end if;
            
            when 11 =>                                 
                -- read
                exi_read_buffer(0) <= exi_do;
      
                if(usb_read_mode_set = '1') then
                   exi_di <= exi_usb_data_in(3);
                end if;
                
                if(id_mode_set = '1') then
                    exi_di <= '0';  -- clear
                end if;
            
            when 12 =>                         -- keep high 40 ns 
                 if(usb_write_mode_set = '1') then
                    usb_wr <= '1';                  -- WR goes high 20ns
                    usb_data(7 downto 0) <= exi_read_buffer;
                end if;
        
                
                if(usb_read_mode_set = '1') then
                   exi_di <= exi_usb_data_in(2);               
                end if;      

            when 13 =>                         
                if(usb_read_mode_set = '1') then
                   exi_di <= exi_usb_data_in(1);
                end if;
  

            when 14 => 
                if(usb_write_mode_set = '1') then   -- go low
                    usb_wr <= '0';                  
                    usb_data(7 downto 0) <= (others => 'Z');
                end if;
                
                if(usb_read_mode_set = '1') then
                   exi_di <= exi_usb_data_in(0);
                end if;
               
            when 15 => 
                
            when 16 => 

            when 17 => 

            when 18 =>

            when 19=> 

            when 20 =>      -- second byte
            when 21 => 

            when 22 => 

            when 23 => 

            when 24 => 

            when 25 => 

            when 26 =>            

            when 27 =>            

            when 28 => 

            when 29 => 

            when 30 => 

            when 31 =>

            when others =>


        end case;
        
        exi_count <= exi_count + 1;
    end if;
end process;

end arch_usbexi;
