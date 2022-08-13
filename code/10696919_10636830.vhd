------------------------------------------------------------
-- Final Examination (Project_Digital_Logic_Design)
-- A.Y. 2021-2022
-- Prof. Fabio Salice
------------------------------------------------------------
-- Group Components
-- 
-- ALEN KAJA (936862 / 10696919)  
-- ELIS KINA (896263 / 10636830)
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
port (
      i_clk : in std_logic;
      i_rst : in std_logic;
      i_start : in std_logic;
      i_data : in std_logic_vector(7 downto 0);
      o_address : out std_logic_vector(15 downto 0);
      o_done : out std_logic;
      o_en : out std_logic;
      o_we : out std_logic;
      o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
      type state is(
      RESET, READY,
      NUM_W, READ_IN, ENTER_FSM,
      S0, S1, S2, S3,
      SAVE_VECTOR,
      CHECK, ITERATOR_UPDATE,
      FIRST_O_WRITE,
      SECOND_O_WRITE,
      DONE);
      
      signal curr_s, last_state : state;
      signal counter : std_logic_vector(15 downto 0);
      signal zero_cell : std_logic_vector(7 downto 0);
      signal input : std_logic_vector(7 downto 0);
      signal output : std_logic_vector(7 downto 0);
      signal i: std_logic_vector( 2 downto 0);
      signal tmp: std_logic_vector( 2 downto 0) := (others =>'0');
      signal flag: std_logic := '0';
      signal mem_write: std_logic_vector(15 downto 0) := (others =>'0');
      
begin
main: process(i_clk)
      begin
      if i_clk'event and i_clk = '0' then
            if i_rst = '1' then
                  curr_s <= RESET;
            else
                  case curr_s IS
                        
                        --reset state
                        when RESET =>
                              o_en <= '0';
                              o_we <= '0';
                              o_done <= '0';
                              o_address <= "0000000000000000";    --initialize the address to the first row of the ram
                              mem_write <= "0000001111100110";    --initialize the memory reference to row 998  
                              curr_s <= READY;
                        
                        --wait for the start signal      
                        when READY =>
                              if i_start = '1' then
                                    o_en <= '1';
                                    curr_s <= NUM_W;
                              end if;
                              last_state <= S0;
                        
                        --read the number of words to encode      
                        when NUM_W =>
                              if(i_data = "00000000") then
                                    o_done <= '1';
                                    curr_s <= DONE;
                              else 
                                    zero_cell <= i_data;
                                    o_address<= "0000000000000001";     --begin to read from the first word
                                    counter <= "0000000000000000";        --initialize word counter to zero
                                    curr_s <= READ_IN;
                              end if;
                        
                        --acquire the byte from the ram (8 bits input)     
                        when READ_IN => 
                              input <= i_data;                         --acquire the word from the memory
                              i <= "111";
                              tmp <= "111";
                              counter <= counter+1;                   --increment number of read words
                              mem_write <= mem_write+2;               --increment memory to the corrent point
                              curr_s <= ENTER_FSM;
                         
                         --prepare to start encoding
                         when ENTER_FSM =>
                              curr_s <= last_state;                   
                         
                         --start of encoding traversing the mealy fsm
                         when S0 =>
                              if input(to_integer(unsigned(i)))='0' then
                                    output(to_integer(unsigned(tmp)) downto to_integer(unsigned(tmp))-1) <= "00";
                                    --last_state <= S0;
                              elsif input(to_integer(unsigned(i)))='1' then
                                    output(to_integer(unsigned(tmp)) downto to_integer(unsigned(tmp))-1) <= "11";
                                    last_state <= S2;
                              end if;
                              curr_s <= CHECK;
                        
                        when S2 =>
                              if input(to_integer(unsigned(i)))='0' then
                                    output(to_integer(unsigned(tmp)) downto to_integer(unsigned(tmp))-1) <= "01";
                                    last_state <= S1;
                              elsif input(to_integer(unsigned(i)))='1' then
                                    output(to_integer(unsigned(tmp)) downto to_integer(unsigned(tmp))-1) <= "10";
                                    last_state <= S3;
                              end if;
                              curr_s <= CHECK;
                              
                        when S1 =>
                              if input(to_integer(unsigned(i)))='0' then
                                    output(to_integer(unsigned(tmp)) downto to_integer(unsigned(tmp))-1) <= "11";
                                    last_state <= S0;
                              elsif input(to_integer(unsigned(i)))='1' then
                                    output(to_integer(unsigned(tmp)) downto to_integer(unsigned(tmp))-1) <= "00";
                                    last_state <= S2;
                              end if;
                              curr_s <= CHECK;
                              
                        when S3 =>
                              if input(to_integer(unsigned(i)))='0' then
                                    output(to_integer(unsigned(tmp)) downto to_integer(unsigned(tmp))-1) <= "10";
                                    last_state <= S1;
                              elsif input(to_integer(unsigned(i)))='1' then
                                    output(to_integer(unsigned(tmp)) downto to_integer(unsigned(tmp))-1) <= "01";
                                    last_state <= S3;
                              end if;
                              curr_s <= CHECK;
                        
                        --check the parsing position     
                        when CHECK =>
                              if( i> "000") then
                                    i <= i-1;
                                    curr_s <= ITERATOR_UPDATE;
                              else 
                                    curr_s <= SAVE_VECTOR;
                              end if;
                       
                        --shift the position of the encoded vector using tmp
                        when ITERATOR_UPDATE =>
                              case i is                    
                                    when "110" => tmp <= "101";
                                    when "101" => tmp <= "011";
                                    when "100" => tmp <= "001";
                                    when "011" => tmp <= "111";
                                    when "010" => tmp <= "101";
                                    when "001" => tmp <= "011";
                                    when "000" => tmp <= "001";
                                    when others => 
                              end case;
                              if(i = "011") then      
                                    curr_s <= SAVE_VECTOR;
                              else  
                                    curr_s <= last_state;
                              end if;                                                              
                       
                        --save the output byte
                        when SAVE_VECTOR =>
                              o_we <= '1';
                              o_data <= output;
                              if(flag = '0') then
                                    o_address <= mem_write;                                    
                                    curr_s <= FIRST_O_WRITE;
                              elsif(flag = '1') then
                                    o_address <= mem_write+1;
                                    curr_s <= SECOND_O_WRITE;
                              end if;                                                         
                        
                        --if we encoded the first 4 bits of the initial 8
                        when FIRST_O_WRITE =>
                              o_we <= '0';
                              flag <= '1';
                              curr_s <= last_state;
                        
                        --if we encoded the last 4 bits of the initial 8
                        when SECOND_O_WRITE =>
                              o_we <= '0';
                              flag <= '0';
                              curr_s <= READ_IN;
                              o_address <= counter + 1 ; 
                              if(conv_integer(counter) = conv_integer(zero_cell)) then
                                    o_done <= '1';
                                    curr_s <= DONE;     
                              end if;
                        
                        --prepare to RESET and wait for a new START signal
                        when DONE =>
                              if (i_start ='0') then
                                    curr_s <= RESET;
                              end if;
                              o_done <= '0';                                  
                              o_we <= '0';                              
                              
                        end CASE;
                  end IF;
            end IF;
      end process;      
end Behavioral;
