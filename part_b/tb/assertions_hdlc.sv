//////////////////////////////////////////////////
// Title:   assertions_hdlc
// Author:  
// Date:    
//////////////////////////////////////////////////

/* The assertions_hdlc module is a test module containing the concurrent
   assertions. It is used by binding the signals of assertions_hdlc to the
   corresponding signals in the test_hdlc testbench. This is already done in
   bind_hdlc.sv 

   For this exercise you will write concurrent assertions for the Rx module:
   - Verify that Rx_FlagDetect is asserted two cycles after a flag is received
   - Verify that Rx_AbortSignal is asserted after receiving an abort flag
*/

module assertions_hdlc (
  output int   ErrCntAssertions,
  input  logic Clk,
  input  logic Rst,
  input  logic Rx,
  input  logic RxD,
  input  logic Rx_FlagDetect,
  input  logic Rx_EoF,
  input  logic Rx_ValidFrame,
  input  logic Rx_AbortDetect,
  input  logic Rx_AbortSignal,
  input  logic Rx_Overflow,
  input  logic Rx_WrBuff,
  input  logic Rx_NewByte,
  input  logic Rx_StartZeroDetect,
  input  logic Tx,
  input  logic Tx_AbortFrame,
  input  logic Tx_ValidFrame,
  input  logic Tx_AbortedTrans,
  input  logic Tx_InitZero,
  input  logic ZeroDetect
);

  initial begin
    ErrCntAssertions  =  0;
  end

  /*******************************************
   *  Verify correct Rx_FlagDetect behavior  *
   *******************************************/

  sequence StartStop_pattern(sig1);
    !sig1 ##1 sig1[*6] ##1 !sig1;
  endsequence

  // #?
  // Check if flag sequence is detected
  property RX_FlagDetect;
    StartStop_pattern(Rx) |-> ##2 Rx_FlagDetect;
  endproperty

  RX_FlagDetect_Assert : assert property (@(posedge Clk) disable iff(!Rst) RX_FlagDetect) begin
    $display("PASS: Flag detect");
  end else begin 
    $error("Flag sequence did not generate FlagDetect"); 
    ErrCntAssertions++; 
  end

  // #5
  // Check if flag sequence is generated
  // Start-flag has 2 cycle delay, Stop-flag has 1 cycle
  property TX_FlagGen;
    !$stable(Tx_ValidFrame) ##0 !Tx_AbortedTrans |-> ##[1:2] StartStop_pattern(Tx);
  endproperty

  TX_FlagGen_Assert : assert property (@(posedge Clk) disable iff(!Rst) TX_FlagGen) begin
    $display("PASS: Flag Generated");
  end else begin 
    $display("ERROR: No flag Generated"); 
    ErrCntAssertions++; 
  end

  /********************************************
   *  Verify correct Rx_AbortSignal behavior  *
   ********************************************/
  // #10
  //If abort is detected during valid frame. then abort signal should go high
  property RX_AbortSignal;
    (Rx_AbortDetect && Rx_ValidFrame) |=> Rx_AbortSignal;
  endproperty

  RX_AbortSignal_Assert : assert property (@(posedge Clk) RX_AbortSignal) begin
    $display("PASS: Abort signal");
  end else begin 
    $display("AbortSignal did not go high after AbortDetect during validframe"); 
    ErrCntAssertions++; 
  end

  // #12
  // End of frame detect
  property RX_EOF;
    $fell(Rx_ValidFrame) |=> Rx_EoF;
  endproperty

  RX_EOF_Assert: assert property (@(posedge Clk) disable iff(!Rst) RX_EOF)
    $display("PASS! End of frame is generated");
  else begin
    $display("ERROR! No end of frame signal");
    ErrCntAssertions++;
  end

  // #6
  // Rx zero removal
  property RX_ZeroRemove;
    RxD[*5] ##0 Rx_ValidFrame |=> (!RxD ##0 ZeroDetect);
  endproperty

  RX_Zero_Assert: assert property (@(posedge Clk) disable iff(!Rst) RX_ZeroRemove)
  else begin
    $display("ERROR! Zero was not removed");
    ErrCntAssertions++;
  end

  // Tx zero insertion
  property TX_ZeroInsert;
    StartStop_pattern(Tx) ##0 Tx_ValidFrame |=> (!Tx_ValidFrame[->1]) within (##[*] Tx[*6]);  
  endproperty

  TX_Zero_Assert: assert property (@(posedge Clk) disable iff(!Rst) TX_ZeroInsert)
  else begin
    $display("ERROR! Zero insert was not generated");
    ErrCntAssertions++;
  end

  sequence Idle_pattern(sig1);
    sig1[*8];
  endsequence

  // #7
  // Rx idle pattern check
  property RX_Idle;
    Idle_pattern(Rx) |=> Rx or StartStop_pattern(Rx);
  endproperty

  RX_Idle_Assert: assert property (@(posedge Clk) RX_Idle)
  else begin
    $display("ERROR! Bad RX idle pattern");
    ErrCntAssertions++;
  end

  // Tx idle pattern generation
  property TX_Idle;
    Idle_pattern(Tx) |=> Tx or StartStop_pattern(Tx);
  endproperty

  TX_Idle_Assert: assert property (@(posedge Clk) TX_Idle)
  else begin
    $display("ERROR! Bad TX idle pattern");
    ErrCntAssertions++;
  end
  
  sequence Abort_pattern(sig1);
    !sig1 ##1 sig1[*7];
  endsequence

  // #8
  // Rx abort pattern check
  property RX_Abort_Flag;
    Abort_pattern(Rx) ##0 Rx_ValidFrame |-> ##2 Rx_AbortDetect;
  endproperty

  RX_Abort_Flag_Assert: assert property (@(posedge Clk) disable iff(!Rst) RX_Abort_Flag)
    $display("PASS! Abort flag detected");
  else begin
    $error("ERROR! Abort flag not detected");
    ErrCntAssertions++;
  end

  // Tx abort pattern generation
  property TX_Abort_Flag;
    $rose(Tx_AbortedTrans) |-> ##2 Abort_pattern(Tx);
  endproperty

  TX_Abort_Flag_Assert: assert property (@(posedge Clk) disable iff(!Rst) TX_Abort_Flag)
    $display("PASS! Abort flag generated");
  else begin
    $display("ERROR! Abort flag not generated");
    ErrCntAssertions++;
  end

  // #13
  // Rx_Overflow
  property RX_ovf;
    Rx_FlagDetect ##0 !Rx_ValidFrame ##1 (Rx_NewByte[->129] within Rx_FlagDetect[->1]) |=> Rx_Overflow;
  endproperty

  RX_ovf_Assert: assert property (@(posedge Clk) RX_ovf)
    $display("PASS! overflow signal is set");
  else begin
    $display("ERROR! Missing overflow signal");
    ErrCntAssertions++;
  end



endmodule
