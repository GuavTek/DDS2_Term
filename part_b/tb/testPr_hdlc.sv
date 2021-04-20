//////////////////////////////////////////////////
// Title:   testPr_hdlc
// Author: 
// Date:  
//////////////////////////////////////////////////

/* testPr_hdlc contains the simulation and immediate assertion code of the
   testbench. 

   For this exercise you will write immediate assertions for the Rx module which
   should verify correct values in some of the Rx registers for:
   - Normal behavior
   - Buffer overflow 
   - Aborts

   HINT:
   - A ReadAddress() task is provided, and addresses are documentet in the 
     HDLC Module Design Description
*/

program testPr_hdlc(
  in_hdlc uin_hdlc
);
  
  int TbErrorCnt;

  /****************************************************************************
   *                                                                          *
   *                               Student code                               *
   *                                                                          *
   ****************************************************************************/

  // VerifyAbortReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer is zero after abort.
  // #2 #3
  task VerifyAbortReceive(logic [127:0][7:0] data, int Size);
    	automatic logic [7:0] ReadData = 8'b0;
	  wait(uin_hdlc.Rx_AbortSignal);

	  ReadAddress(3'h2, ReadData);

	  // Rx_AbortSignal
    assert (ReadData & (1 << 3))
      $display("PASS! Abortsignal was set"); 
    else begin
      $display("ERROR! Abortsignal was not set");
      TbErrorCnt++;
    end

    // !Rx_FrameError
    assert (!(ReadData & (1 << 2)))
      $display("PASS! No frame errors");
    else begin
      $display("ERROR! Frame error flag set");
      TbErrorCnt++;
    end

    // !Rx_Overflow
    assert (!(ReadData & (1 << 4)))
      $display("PASS! No overflow flag");
    else begin
      $display("ERROR! Overflow flag set");
      TbErrorCnt++;
    end

    // !Rx_Ready
    assert (!(ReadData & (1 << 0)))
      $display("PASS! Rx buffer has no data");
    else begin
      $display("ERROR! Rx buffer has data");
      TbErrorCnt++;
    end


        for (int i = 0; i < 128; i++) begin
      ReadAddress(3'h3, ReadData);
      if (ReadData != 8'b0) begin
        break;
      end
    end

    assert (ReadData == 8'b0) 
      $display("PASS! Data buffer is empty");
    else begin
      $display("ERROR! Data buffer is not empty, byte was %h", ReadData);
      TbErrorCnt++;
    end

  endtask

  // VerifyNormalReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer contains correct data.
  // #1 #3 #14 #15??
  task VerifyNormalReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    wait(uin_hdlc.Rx_Ready);

    ReadAddress(3'h2, ReadData);

    // Rx_Ready
    assert (ReadData & (1 << 0))
      $display("PASS! Rx buffer is ready");
    else begin
      $display("ERROR! Rx buffer is not ready?!?");
      TbErrorCnt++;
    end

    // !Rx_FrameError
    assert (!(ReadData & (1 << 2)))
      $display("PASS! No frame error"); 
    else begin
      $display("ERROR! FrameError detected");
      TbErrorCnt++;
    end

    // !Rx_AbortSignal
    assert (!(ReadData & (1 << 3)))
      $display("PASS! Abort flag not set");
    else begin
      $display("ERROR! Abort flag set");
      TbErrorCnt++;
    end

    // !Rx_Overflow
    assert (!(ReadData & (1 << 4)))
      $display("PASS! No overflow"); 
    else begin
      $display("ERROR! Data overflew");
      TbErrorCnt++;
    end

    ReadAddress(3'h4, ReadData);

    assert (ReadData == Size)
      $display("PASS! Correct frame size");
    else begin
      $display("ERROR! Wrong frame size");
      TbErrorCnt++;
    end

    for (int i = 0; i < Size+2; i++) begin
      ReadAddress(3'h3, ReadData);
      assert (data[i] == ReadData)
        $display("PASS! data in Rx buffer correct");
      else begin
        $display("ERROR! wrong data in Rx buffer position %d. Found %h, should be %h", i, ReadData, data[i]);
        TbErrorCnt++;
      end
    end

    VerifyCRC(data, Size);

  endtask

  // VerifyOverflowReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer contains correct data.
  // #3
  task VerifyOverflowReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    wait(uin_hdlc.Rx_Ready);

    // Read RX_SC
    ReadAddress(3'h2, ReadData);
    
    // Rx_Overflow
    assert (ReadData & (1 << 4))
      $display("PASS! Overflow flag set");
    else begin
      $display("ERROR! Overflow flag not set");
      TbErrorCnt++;
    end

    // Rx_Ready
    assert (ReadData & (1 << 0))
      $display("PASS! Buffer has data to read");
    else begin
      $display("ERROR! Buffer has no data");
      TbErrorCnt++;
    end
    
    // !Rx_FrameError
    assert (!(ReadData & (1 << 2)))
      $display("PASS! No frame errors");
    else begin
      $display("ERROR! Frame error detected");
      TbErrorCnt++;
    end

    // !Rx_AbortSignal
    assert (!(ReadData & (1 << 3)))
      $display("PASS! No abort");
    else begin
      $display("ERROR! Abort signal asserted");
      TbErrorCnt++;
    end
  endtask

  // #16
  // Rx frame error
  task VerifyFrameErrorReceive (logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    wait(uin_hdlc.Rx_Ready);

    ReadAddress(3'h2, ReadData);

    assert (!(ReadData & (1 << 4)))
      $display("PASS! Rx_Overflow flag not set"); 
    else begin
      $display("ERROR! Rx_Overflow flag is set");
      TbErrorCnt++;
    end

    assert (!(ReadData & (1 << 3)))
      $display("PASS! Rx_AbortSignal flag not set"); 
    else begin
      $display("ERROR! Rx_AbortSignal flag is set");
      TbErrorCnt++;
    end

    assert ((ReadData & (1 << 2)))
      $display("PASS! Rx_FrameError flag is set"); 
    else begin
      $display("ERROR! Rx_FrameError flag not set");
      TbErrorCnt++;
    end

    assert ((ReadData & (1 << 0)))
      $display("PASS! Rx_Ready flag is set"); 
    else begin
      $display("ERROR! Rx_Ready flag not set");
      TbErrorCnt++;
    end

  endtask //VerifyFrameErrorReceive

  // #11
  // CRC verification
  task VerifyCRC(logic [127:0][7:0] data, int Size);
    automatic logic[16:0] P = 17'h14003; // reversed 17'h18005
    automatic logic[15:0] fcs = 0;
    automatic logic[16:0] temp = 0;
    automatic logic[15:0] crc = {data[Size+1], data[Size]};

    fcs[7:0] = data[0];
    fcs[15:8] = data[1];

    for (int i = 0; i < Size; i++) begin
      for (int j = 0; j < 8; j++) begin
        temp = fcs[0] ? P ^ {data[i+2][j], fcs}:{data[i+2][j], fcs};
        fcs = temp[16:1];
      end
    end

    assert (fcs == 0) 
      $display("PASS! Correct CRC generated");
    else begin
      $display("ERROR! CRC bytes don't match. Got %4h", fcs);
      TbErrorCnt++;  
    end
  endtask

  // #4 #17
  // Tx normal verification
  task VerifyNormalSend (logic [127:0][7:0] data, int Size);
	  logic [7:0] ReadData;
    
    for (int i = 0; i < Size ; i++) begin
      for (int j = 0; j < 9; j++) begin
        if(uin_hdlc.Tx_Data == data[i])
          break;
      end
      assert (data[i] == uin_hdlc.Tx_Data)
        $display("PASS! data in Tx buffer correct");
      else begin
        $display("ERROR! wrong data in Tx buffer position %d. Found %h, should be %h", i, uin_hdlc.Tx_Data[i], data[i]);
        TbErrorCnt++;
      end
    end

    // Tx_Done
    for(int i = 0; i < 32; i++) begin
      ReadAddress(3'h0, ReadData);
      if (ReadData & (1 << 0))
        break;
    end

    assert(ReadData & (1 << 0))
      $display("PASS! TX_Done flag asserted");
    else begin
      $display("ERROR! Missing TX_Done flag");
      TbErrorCnt++;
    end
  endtask //VerifyNormalSend

  // #9
  // Tx abort verification
  task VerifyAbortSend (logic [127:0][7:0] data, int Size);
	  logic [7:0] ReadData;

    for(int i = 0; i < 32; i++) begin
      ReadAddress(3'h0, ReadData);
      if (ReadData & (1 << 3))
        break;
    end

    assert(ReadData & (1 << 3))
      $display("PASS! TX_AbortedTrans flag asserted");
    else begin
      $display("ERROR! Missing TX_AbortedTrans flag");
      TbErrorCnt++;
    end
  endtask //VerifyAbortSend


  // #18
  // Tx overflow
  task VerifyOverflowSend (logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;

    ReadAddress(3'h0, ReadData);

    assert(ReadData & (1 << 4))
      $display("PASS! TX_Full flag asserted");
    else begin
      $display("ERROR! Missing TX_Full flag");
      TbErrorCnt++;
    end
  endtask //VerifyOverflowSend


  /****************************************************************************
   *                                                                          *
   *                             Simulation code                              *
   *                                                                          *
   ****************************************************************************/

  initial begin
    $display("*************************************************************");
    $display("%t - Starting Test Program", $time);
    $display("*************************************************************");

    Init();

    //Receive: Size, Abort, FCSerr, NonByteAligned, Overflow, Drop, SkipRead
    Receive( 10, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 40, 1, 0, 0, 0, 0, 0); //Abort
    Receive(126, 0, 0, 0, 1, 0, 0); //Overflow
    Receive(126, 0, 0, 0, 0, 0, 0); //Normal
    Receive(122, 1, 0, 0, 0, 0, 0); //Abort
    Receive(126, 0, 0, 0, 1, 0, 0); //Overflow
    Receive( 25, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 69, 0, 1, 0, 0, 0, 0); //FCSerr
    Receive( 30, 0, 0, 1, 0, 0, 0); //NonByteAligned
    Receive( 78, 0, 0, 3, 0, 0, 0); //NonByteAligned
    Receive(  9, 0, 0, 7, 0, 0, 0); //NonByteAligned
    

    //Send: Size, Abort, Overflow
    Send( 24, 0, 0);                 //Normal
    Send( 66, 1, 0);                 //Abort
    Send(126, 0, 1);                //Overflow
    
    

    $display("*************************************************************");
    $display("%t - Finishing Test Program", $time);
    $display("*************************************************************");
    $stop;
  end

  final begin

    $display("*********************************");
    $display("*                               *");
    $display("* \tAssertion Errors: %0d\t  *", TbErrorCnt + uin_hdlc.ErrCntAssertions);
    $display("*                               *");
    $display("*********************************");

  end

  task Init();
    uin_hdlc.Clk         =   1'b0;
    uin_hdlc.Rst         =   1'b0;
    uin_hdlc.Address     = 3'b000;
    uin_hdlc.WriteEnable =   1'b0;
    uin_hdlc.ReadEnable  =   1'b0;
    uin_hdlc.DataIn      =     '0;
    uin_hdlc.TxEN        =   1'b1;
    uin_hdlc.Rx          =   1'b1;
    uin_hdlc.RxEN        =   1'b1;

    TbErrorCnt = 0;

    #1000ns;
    uin_hdlc.Rst         =   1'b1;
  endtask

  task WriteAddress(input logic [2:0] Address ,input logic [7:0] Data);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Address     = Address;
    uin_hdlc.WriteEnable = 1'b1;
    uin_hdlc.DataIn      = Data;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.WriteEnable = 1'b0;
  endtask

  task ReadAddress(input logic [2:0] Address ,output logic [7:0] Data);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Address    = Address;
    uin_hdlc.ReadEnable = 1'b1;
    #100ns;
    Data                = uin_hdlc.DataOut;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.ReadEnable = 1'b0;
  endtask

  task InsertFlagOrAbort(int flag);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b0;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    if(flag)
      uin_hdlc.Rx = 1'b0;
    else
      uin_hdlc.Rx = 1'b1;
  endtask

  task MakeRxStimulus(logic [127:0][7:0] Data, int Size);
    logic [4:0] PrevData;
    PrevData = '0;
    for (int i = 0; i < Size; i++) begin
      for (int j = 0; j < 8; j++) begin
        if(&PrevData) begin
          @(posedge uin_hdlc.Clk);
          uin_hdlc.Rx = 1'b0;
          PrevData = PrevData >> 1;
          PrevData[4] = 1'b0;
        end

        @(posedge uin_hdlc.Clk);
        uin_hdlc.Rx = Data[i][j];

        PrevData = PrevData >> 1;
        PrevData[4] = Data[i][j];
      end
    end
  endtask

  task Receive(int Size, int Abort, int FCSerr, int NonByteAligned, int Overflow, int Drop, int SkipRead);
    logic [127:0][7:0] ReceiveData;
    logic       [15:0] FCSBytes;
    logic   [2:0][7:0] OverflowData;
    string msg;
    if(Abort)
      msg = "- Abort";
    else if(FCSerr)
      msg = "- FCS error";
    else if(NonByteAligned)
      msg = "- Non-byte aligned";
    else if(Overflow)
      msg = "- Overflow";
    else if(Drop)
      msg = "- Drop";
    else if(SkipRead)
      msg = "- Skip read";
    else
      msg = "- Normal";
    $display("*************************************************************");
    $display("%t - Starting task Receive %s", $time, msg);
    $display("*************************************************************");

    for (int i = 0; i < Size; i++) begin
      ReceiveData[i] = $urandom;
    end
    ReceiveData[Size]   = '0;
    ReceiveData[Size+1] = '0;

    //Calculate FCS bits;
    GenerateFCSBytes(ReceiveData, Size, FCSBytes);
    ReceiveData[Size]   = FCSBytes[7:0];
    ReceiveData[Size+1] = FCSBytes[15:8];

    //Enable FCS
    if(!Overflow && !NonByteAligned)
      WriteAddress(3'h2, 8'h20);
    else
      WriteAddress(3'h2, 8'h00);

    //Generate stimulus
    InsertFlagOrAbort(1);
    
    MakeRxStimulus(ReceiveData, Size + 2);
    
    if(Overflow) begin
      OverflowData[0] = 8'h44;
      OverflowData[1] = 8'hBB;
      OverflowData[2] = 8'hCC;
      MakeRxStimulus(OverflowData, 3);
    end 

    if(NonByteAligned) begin
      uin_hdlc.Rx = 1'b0;
      repeat(NonByteAligned)
        @(posedge uin_hdlc.Clk);
    end

    if(Abort) begin
      InsertFlagOrAbort(0);
    end else begin
      InsertFlagOrAbort(1);
    end

    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;

    repeat(8)
      @(posedge uin_hdlc.Clk);

    if(Abort)
      VerifyAbortReceive(ReceiveData, Size);
    else if(Overflow)
      VerifyOverflowReceive(ReceiveData, Size);
    else if(FCSerr || NonByteAligned)
      VerifyFrameErrorReceive(ReceiveData, Size);
    else if(!SkipRead)
      VerifyNormalReceive(ReceiveData, Size);

    #5000ns;
  endtask

  task Send(int Size, int Abort, int Overflow);
    logic [127:0][7:0] SendData;
    logic       [15:0] FCSBytes;
    logic   [2:0][7:0] OverflowData;
    string msg;
    if(Abort)
      msg = "- Abort";
    else if(Overflow)
      msg = "- Overflow";
    else
      msg = "- Normal";
    $display("*************************************************************");
    $display("%t - Starting task Send %s", $time, msg);
    $display("*************************************************************");

    for (int i = 0; i < Size; i++) begin
      SendData[i] = $urandom;
    end
    SendData[Size]   = '0;
    SendData[Size+1] = '0;

    //Calculate FCS bits;
    GenerateFCSBytes(SendData, Size, FCSBytes);
    SendData[Size]   = FCSBytes[7:0];
    SendData[Size+1] = FCSBytes[15:8];

    //Write TX buffer
    for(int i = 0; i < Size; i++) begin
      WriteAddress(3'h1, SendData[i]);
    end

    if(Overflow) begin
      WriteAddress(3'h1, 8'h66);
      WriteAddress(3'h1, 8'h7f);
      WriteAddress(3'h1, 8'hb0);
      VerifyOverflowSend(SendData, Size);
    end
    
    //Start Transmission
    WriteAddress(3'h0, 8'h02);

    while(!uin_hdlc.Tx_ValidFrame);   // Let transmission start

    if(Abort) begin
      repeat(16)
      @(posedge uin_hdlc.Clk);
      WriteAddress(3'h0, 8'h04);        // Set abort signal
      VerifyAbortSend(SendData, Size);  // Run assertions
    end else if(!Overflow) begin
      VerifyNormalSend(SendData, Size);
    end

    #5000ns;
  endtask

  task GenerateFCSBytes(logic [127:0][7:0] data, int size, output logic[15:0] FCSBytes);
    logic [23:0] CheckReg;
    CheckReg[15:8]  = data[1];
    CheckReg[7:0]   = data[0];
    for(int i = 2; i < size+2; i++) begin
      CheckReg[23:16] = data[i];
      for(int j = 0; j < 8; j++) begin
        if(CheckReg[0]) begin
          CheckReg[0]    = CheckReg[0] ^ 1;
          CheckReg[1]    = CheckReg[1] ^ 1;
          CheckReg[13:2] = CheckReg[13:2];
          CheckReg[14]   = CheckReg[14] ^ 1;
          CheckReg[15]   = CheckReg[15];
          CheckReg[16]   = CheckReg[16] ^1;
        end
        CheckReg = CheckReg >> 1;
      end
    end
    FCSBytes = CheckReg;
  endtask

endprogram
