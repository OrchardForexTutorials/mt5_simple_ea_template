//+------------------------------------------------------------------+
//|                                                   MACDCustom.mq5 |
//|                               Copyright 2012-2020, Orchard Forex |
//|                                     https://www.orchardforex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012-2020, Novateq Pty Ltd"
#property link "https://www.orchardforex.com"
#property version "1.00"

//	MACD indicator inputs
input int                InpFastEmaPeriod   = 12;          //	Fast EMA Period
input int                InpSlowEmaPeriod   = 26;          //	Slow EMA Period
input int                InpSignalSmaPeriod = 9;           //	Signal SMA Period
input ENUM_APPLIED_PRICE InpAppliedPrice    = PRICE_CLOSE; //	Applied Price

input int                InpTakeProfitPts   = 100; //	Take profit points
input int                InpStopLossPts     = 100; //	Stop loss points

input double             InpOrderSize       = 0.01;     //	Order size
input string             InpTradeComment    = __FILE__; //	Trade comment
input int                InpMagicNumber     = 2000001;  //	Magic number

double                   TakeProfit;
double                   StopLoss;

//
//	Identify the buffer numbers
//
const string             IndicatorName = "Examples\\MACD";
const int                IndexMACD     = 0;
const int                IndexSignal   = 1;
int                      Handle;
double                   BufferMACD[3];
double                   BufferSignal[3];

#include <Trade\Trade.mqh>
CTrade *Trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int     OnInit() {

   Trade = new CTrade();
   Trade.SetExpertMagicNumber( InpMagicNumber );

   double point = SymbolInfoDouble( Symbol(), SYMBOL_POINT );
   TakeProfit   = InpTakeProfitPts * point;
   StopLoss     = InpStopLossPts * point;

   Handle       = iCustom( Symbol(), Period(), IndicatorName, InpFastEmaPeriod, InpSlowEmaPeriod, InpSignalSmaPeriod, InpAppliedPrice );

   if ( Handle == INVALID_HANDLE ) {
      PrintFormat( "Error %i", GetLastError() );
      return ( INIT_FAILED );
   }

   return ( INIT_SUCCEEDED );
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit( const int reason ) {

   IndicatorRelease( Handle );
   delete Trade;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

   //
   //	Where this is to only run once per bar
   //
   if ( !NewBar() ) return;

   //
   //	Perform any calculations and analysis here
   //
   int cnt = CopyBuffer( Handle, IndexMACD, 0, 3, BufferMACD );
   if ( cnt < 3 ) return;
   cnt                  = CopyBuffer( Handle, IndexSignal, 0, 3, BufferSignal );

   //
   //	Execute the strategy here
   //
   double currentMACD   = BufferMACD[1];
   double currentSignal = BufferSignal[1];
   double priorMACD     = BufferMACD[0];
   double priorSignal   = BufferSignal[0];

   bool   buyCondition  = ( priorMACD < 0 && priorMACD <= priorSignal ) //	Last bar signal above MACD
                       && ( currentMACD > currentSignal );              //	MACD has crossed
   bool sellCondition = ( priorMACD > 0 && priorMACD >= priorSignal )   //	Last bar signal below MACD
                        && ( currentMACD < currentSignal );             //	MACD has crossed

   if ( buyCondition ) {
      OrderOpen( ORDER_TYPE_BUY );
   }
   else if ( sellCondition ) {
      OrderOpen( ORDER_TYPE_SELL );
   }

   //
   //	Save any information for next time
   //

   return;
}

//+------------------------------------------------------------------+

bool NewBar() {

   static datetime currentTime    = 0;
   datetime        currentBarTime = iTime( Symbol(), Period(), 0 );
   if ( currentBarTime != currentTime ) {
      currentTime = currentBarTime;
      return ( true );
   }
   return ( false );
}

bool OrderOpen( ENUM_ORDER_TYPE orderType ) {

   double price;
   double stopLossPrice;
   double takeProfitPrice;

   if ( orderType == ORDER_TYPE_BUY ) {
      price           = NormalizeDouble( SymbolInfoDouble( Symbol(), SYMBOL_ASK ), Digits() );
      stopLossPrice   = NormalizeDouble( price - StopLoss, Digits() );
      takeProfitPrice = NormalizeDouble( price + TakeProfit, Digits() );
   }
   else if ( orderType == ORDER_TYPE_SELL ) {
      price           = NormalizeDouble( SymbolInfoDouble( Symbol(), SYMBOL_BID ), Digits() );
      stopLossPrice   = NormalizeDouble( price + StopLoss, Digits() );
      takeProfitPrice = NormalizeDouble( price - TakeProfit, Digits() );
   }
   else
      return ( false );

   Trade.PositionOpen( Symbol(), orderType, InpOrderSize, price, stopLossPrice, takeProfitPrice, InpTradeComment );

   return ( true );
}
