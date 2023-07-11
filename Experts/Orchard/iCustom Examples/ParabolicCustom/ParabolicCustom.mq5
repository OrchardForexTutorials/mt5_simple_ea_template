//+------------------------------------------------------------------+
//|                                              ParabolicCustom.mq5 |
//|                               Copyright 2012-2020, Orchard Forex |
//|                                     https://www.orchardforex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012-2020, Orchard Forex"
#property link "https://www.orchardforex.com"
#property version "1.00"

input double InpStep         = 0.02; //	Step
input double InpMaximum      = 0.2;  //	Maximum

input double InpOrderSize    = 0.01;     //	Order size
input string InpTradeComment = __FILE__; //	Trade comment
input int    InpMagicNumber  = 2000001;  //	Magic number

//
//	Identify the buffer numbers
//
const string IndicatorName   = "Examples\\ParabolicSAR";
const int    IndexSAR        = 0;
int          Handle;
double       BufferSAR[3];

#include <Trade\Trade.mqh>
CTrade *Trade;

int     OnInit() {

   Trade = new CTrade();
   Trade.SetExpertMagicNumber( InpMagicNumber );

   Handle = iCustom( Symbol(), Period(), IndicatorName, InpStep, InpMaximum );

   if ( Handle == INVALID_HANDLE ) {
      PrintFormat( "Error %i", GetLastError() );
      return ( INIT_FAILED );
   }

   return ( INIT_SUCCEEDED );
}

void OnDeinit( const int reason ) {

   IndicatorRelease( Handle );
   delete Trade;
}

void OnTick() {

   //
   //	Where this is to only run once per bar
   //
   if ( !NewBar() ) return;

   //
   //	Perform any calculations and analysis here
   //
   int cnt = CopyBuffer( Handle, IndexSAR, 0, 3, BufferSAR );
   if ( cnt < 3 ) return;

   double priorSAR      = BufferSAR[0];
   double currentSAR    = BufferSAR[1];
   double priorClose    = iClose( Symbol(), Period(), 2 );
   double close         = iClose( Symbol(), Period(), 1 );

   //
   //	Execute the strategy here
   //
   bool   buyCondition  = ( priorSAR > priorClose ) && ( currentSAR < close );
   bool   sellCondition = ( priorSAR < priorClose ) && ( currentSAR > close );

   if ( buyCondition ) {
      CloseAll( POSITION_TYPE_SELL );
      OrderOpen( ORDER_TYPE_BUY );
   }
   else if ( sellCondition ) {
      CloseAll( POSITION_TYPE_BUY );
      OrderOpen( ORDER_TYPE_SELL );
   }

   //
   //	Save any information for next time
   //

   return;
}

bool NewBar() {

   static datetime prevTime    = 0;
   datetime        currentTime = iTime( Symbol(), Period(), 0 );
   if ( currentTime != prevTime ) {
      prevTime = currentTime;
      return ( true );
   }
   return ( false );
}

void CloseAll( ENUM_POSITION_TYPE positionType ) {

   int cnt = PositionsTotal();
   for ( int i = cnt - 1; i >= 0; i-- ) {
      ulong ticket = PositionGetTicket( i );
      if ( ticket > 0 ) {
         if ( PositionGetString( POSITION_SYMBOL ) == Symbol() && PositionGetInteger( POSITION_MAGIC ) == InpMagicNumber && PositionGetInteger( POSITION_TYPE ) == positionType ) {
            Trade.PositionClose( ticket );
         }
      }
   }
}

bool OrderOpen( ENUM_ORDER_TYPE orderType ) {

   double price = ( orderType == ORDER_TYPE_BUY ) ? SymbolInfoDouble( Symbol(), SYMBOL_ASK ) : SymbolInfoDouble( Symbol(), SYMBOL_BID );

   Trade.PositionOpen( Symbol(), orderType, InpOrderSize, price, 0, 0, InpTradeComment );

   return ( true );
}
