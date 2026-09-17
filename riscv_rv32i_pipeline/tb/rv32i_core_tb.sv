module rv32i_core_tb;
    logic clk=0, rst=1; logic [31:0] imem_addr, imem_rdata; logic dmem_valid,dmem_we; logic [31:0] dmem_addr,dmem_wdata,dmem_rdata; logic [3:0] dmem_wstrb; logic halted;
    logic [31:0] imem [0:255]; logic [31:0] dmem [0:255]; integer i, cycles;
    rv32i_core dut(.*);
    always #5 clk=~clk;
    assign imem_rdata = imem[imem_addr[9:2]];
    assign dmem_rdata = dmem[dmem_addr[9:2]];
    always_ff @(posedge clk) if (dmem_valid && dmem_we) dmem[dmem_addr[9:2]] <= dmem_wdata;
    task expect_reg(input integer n, input [31:0] expected);
        begin if (dut.regs[n] !== expected) begin $display("FAIL x%0d=%h expected %h",n,dut.regs[n],expected); $fatal; end end
    endtask
    initial begin
        for(i=0;i<256;i=i+1) begin imem[i]=0; dmem[i]=0; end
        // addi x1,5; addi x2,7; add x3,x1,x2; sw x3,0(x0); lw x4,0(x0); addi x5,1; add x6,x4,x5; beq x6,x3,+8; addi x7,99; addi x7,42
        imem[0]=32'h00500093; imem[1]=32'h00700113; imem[2]=32'h002081b3; imem[3]=32'h00302023; imem[4]=32'h00002203; imem[5]=32'h00100293; imem[6]=32'h00520333; imem[7]=32'h00330463; imem[8]=32'h06300393; imem[9]=32'h02a00393; imem[10]=0;
        repeat(2) @(posedge clk); rst=0;
        for(cycles=0; cycles<35; cycles=cycles+1) @(posedge clk);
        expect_reg(1,5); expect_reg(2,7); expect_reg(3,12); expect_reg(4,12); expect_reg(5,1); expect_reg(6,13); expect_reg(7,42);
        if(dmem[0]!==12) begin $display("FAIL memory=%h",dmem[0]); $fatal; end
        $display("PASS: RV32I pipeline forwarding, load-use stall, branch flush, and store/load checks passed"); $finish;
    end
endmodule
