// Helper module to convert Binary to BCD (Binary Coded Decimal)
// Works for 11-bit numbers (Max value 2047 , for timer and score)
//using shift_add_3 algorithm

module bin_to_bcd_11bit (
    input logic [10:0] binary,   // Input: The integer number
    output logic [3:0] hundreds, // Output: Hundreds digit
    output logic [3:0] tens,     // Output: Tens digit
    output logic [3:0] ones      // Output: Units digit
);
    // Register to hold the shifting bits
    // Size = 11 bits (input) + 12 bits (3 digits * 4 bits) = 23 bits
    logic [22:0] shift_reg; 
    integer i;

    always_comb begin
        // Initialize and load the binary number into the lower bits
        shift_reg = 0;
        shift_reg[10:0] = binary; 

        // Shift-Add-3 Algorithm Loop (iterate once for each input bit)
        for (i = 0; i < 11; i = i + 1) begin
            // Check Units column (bits 14 down to 11)
            if (shift_reg[14:11] >= 5)
                shift_reg[14:11] = shift_reg[14:11] + 3;
            
            // Check Tens column (bits 18 down to 15)
            if (shift_reg[18:15] >= 5)
                shift_reg[18:15] = shift_reg[18:15] + 3;
            
            // Check Hundreds column (bits 22 down to 19)
            if (shift_reg[22:19] >= 5)
                shift_reg[22:19] = shift_reg[22:19] + 3;

            // Shift entire register left by 1 position
            shift_reg = shift_reg << 1;
        end
        
        // Assign the resulting BCD nibbles to the outputs
        hundreds = shift_reg[22:19];
        tens     = shift_reg[18:15];
        ones     = shift_reg[14:11];
    end
endmodule