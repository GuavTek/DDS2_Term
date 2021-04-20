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
  input  logic Tx_InitZero
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

  RX_FlagDetect_Assert : assert property (@(posedge Clk) RX_FlagDetect) begin
    $display("PASS: Flag detect");
  end else begin 
    $error("Flag sequence did not generate FlagDetect"); 
    ErrCntAssertions++; 
  end

  // #5
  // Check if flag sequence is generated
  // Start-flag has 2 cycle delay, Stop-flag has 1 cycle
  property TX_FlagGen;
    !$stable(Tx_ValidFrame) |-> ##[1:2] StartStop_pattern(Tx);
  endproperty

  TX_FlagGen_Assert : assert property (@(posedge Clk) TX_FlagGen) begin
    $display("PASS: Flag Generated");
  end else begin 
    $error("ERROR: No flag Generated"); 
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
    $error("AbortSignal did not go high after AbortDetect during validframe"); 
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
  // Rx zero removal (or start/stop sequence)
  property RX_ZeroRemove;
    Rx[*5] |=> (!Rx ##0 Rx_StartZeroDetect) or (Rx ##1 !Rx);
  endproperty

  RX_Zero_Assert: assert property (@(posedge Clk) disable iff(!Rst) RX_ZeroRemove);
  else begin
    $display("ERROR! Zero was not removed");
    ErrCntAssertions++;
  end

  // Tx zero insertion
  property TX_ZeroInsert;
    StartStop_pattern(Tx) ##0 Tx_ValidFrame |=> !(##[*] Tx[*6]) throughout (!Tx_ValidFrame[->1]) 
  endproperty

  TX_Zero_Assert: assert property (@(posedge Clk) disable iff(!Rst) TX_ZeroInsert);
  else begin
    $display("ERROR! Zero insert was not generated");
    ErrCntAssertions++;
  end

  sequence Idle_pattern(sig1);
    sig1[*8];
  endsequence

  // #7
  // Rx idle pattern check


  // Tx idle pattern generation


  
  sequence Abort_pattern(sig1);
    !sig1 ##1 sig1[*7];
  endsequence

  // #8
  // Rx abort pattern check


  // Tx abort pattern generation


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
