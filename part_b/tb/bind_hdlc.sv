//////////////////////////////////////////////////
// Title:   bind_hdlc
// Author:  Karianne Krokan Kragseth
// Date:    20.10.2017
//////////////////////////////////////////////////

module bind_hdlc ();

  bind test_hdlc assertions_hdlc u_assertion_bind(
    .ErrCntAssertions (uin_hdlc.ErrCntAssertions),
    .Clk              (uin_hdlc.Clk),
    .Rst              (uin_hdlc.Rst),
    .Rx               (uin_hdlc.Rx),
    .RxD          (uin_hdlc.RxD),
    .Rx_FlagDetect    (uin_hdlc.Rx_FlagDetect),
    .Rx_ValidFrame    (uin_hdlc.Rx_ValidFrame),
    .Rx_AbortDetect   (uin_hdlc.Rx_AbortDetect),
    .Rx_AbortSignal   (uin_hdlc.Rx_AbortSignal),
    .Rx_Overflow      (uin_hdlc.Rx_Overflow),
    .Rx_WrBuff        (uin_hdlc.Rx_WrBuff),
    .Rx_EoF           (uin_hdlc.Rx_EoF),
    .Rx_NewByte       (uin_hdlc.Rx_NewByte),
    .Rx_StartZeroDetect (uin_hdlc.Rx_StartZeroDetect),
    .Tx               (uin_hdlc.Tx),
    .Tx_ValidFrame    (uin_hdlc.Tx_ValidFrame),
    .Tx_AbortFrame    (uin_hdlc.Tx_AbortFrame),
    .Tx_AbortedTrans  (uin_hdlc.Tx_AbortedTrans),
    .Tx_InitZero      (uin_hdlc.Tx_InitZero),
    .ZeroDetect       (uin_hdlc.ZeroDetect)
  );

endmodule
