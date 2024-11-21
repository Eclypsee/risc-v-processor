IMPORTANT!!!
In order to compile and use on the Basys board, you must follow the steps below:
1. download files
2. import into Xilinx Vivado as design sources
3. import the constraints.xdc file as a constraints file
4. import otter_memory.mem memory file as a design source

NOTES:
   note that this memory file goes through a typical list of test cases for a 32 bit risc v processor
   the processor will pass every single test case
   each increment on the 7-seg is a group of cases for testing a specific instruction
   each led that turns on is a single case for the specific instruction 
   etc AUIPC has many test cases, and leds will light up sequentially. After AUIPC test cases are finished, 7-seg increments
   
   switch 0(one on the very right of the board) will pause the program
   switch 1(the second one to the right) will pause the program if we fail a test case
   switch 2(the third one to the right) adds a delay so you can see the test cases go through, if you do not turn this on, it cycles through too fast for the typical human eye to see

   The Test_All_Debug.txt is the assembly code of the test cases, useful for debugging purposes for your own processor
   
   
   

