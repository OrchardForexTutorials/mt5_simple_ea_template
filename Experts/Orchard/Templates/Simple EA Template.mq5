/*

   Simple EA Template.mq4
   Copyright 2012-2020, OrchardForex.com
   https://www.orchardforex.com

   Version History
   ===============

   1.00	Initial version

   1.01	Change order return type to int and return order number

   1.10	Added the function to close all based on type
         Allowed for stop loss and take profit of zero
         Fixed error in open return code if an invalid type passed in

   ===============

//*/

#property copyright "Copyright 2012-2020, OrchardForex.com"
#property link "https://www.orchardforex.com"
#property version "1.10"

//
//	For the basic template enter sl and tp in points, this usually changes by strategy
//
input int    InpTakeProfitPts = 100; //	Take profit points
input int    InpStopLossPts   = 100; //	Stop loss points

//
//	Standard inputs
//
input double InpOrderSize     = 0.01;     //	Order size
input string InpTradeComment  = __FILE__; //	Trade comment
input int    InpMagicNumber   = 2000001;  //	Magic number

double       TakeProfit;
double       StopLoss;
bool         CloseOpposite;

//
//	Use CTrade, easier than doing our own coding
//
#include <Trade\Trade.mqh>
CTrade *Trade;

int     OnInit() {

   //
   //	Create a pointer to a ctrade object
   //
   Trade = new CTrade();
   Trade.SetExpertMagicNumber( InpMagicNumber );

   //
   //	Convert the input point sl tp to double
   //
   double point  = SymbolInfoDouble( Symbol(), SYMBOL_POINT );
   TakeProfit    = InpTakeProfitPts * point;
   StopLoss      = InpStopLossPts * point;

   CloseOpposite = false;

   return ( INIT_SUCCEEDED );
}

void OnDeinit( const int reason ) {

   //
   //	Clean up the trade object
   //
   delete Trade;
}

void OnTick() {

   //
   //	Where this is to only run once per bar, just return if the bar hasn't changed
   //
   if ( !NewBar() ) return;

   //
   //	Perform any calculations and analysis here
   //

   //
   //	Execute the strategy here
   //
   bool buyCondition  = false; //	replace false with the strategy condition
   bool sellCondition = false;

   if ( buyCondition ) {
      if ( CloseOpposite ) CloseAll( POSITION_TYPE_SELL );
      OrderOpen( ORDER_TYPE_BUY, StopLoss, TakeProfit );
   }
   else if ( sellCondition ) {
      if ( CloseOpposite ) CloseAll( POSITION_TYPE_BUY );
      OrderOpen( ORDER_TYPE_SELL, StopLoss, TakeProfit );
   }

   //
   //	Save any information for next time
   //

   return;
}

//
//	true/false has the bar changed
//
bool NewBar() {

   static datetime priorTime   = 0;
   datetime        currentTime = iTime( Symbol(), Period(), 0 );
   bool            result      = ( currentTime != priorTime );
   priorTime                   = currentTime;
   return ( result );
}

//
//	Close all trades of the specified type - for strategies that call for closing the opposite side
//
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

//
//	Simple function to open a new order
//
int OrderOpen( ENUM_ORDER_TYPE orderType, double stopLoss, double takeProfit ) {

   double openPrice;
   double stopLossPrice;
   double takeProfitPrice;

   //
   //	Calculate the open price, take profit and stop loss prices based on the order type
   //
   if ( orderType == ORDER_TYPE_BUY ) {
      openPrice       = NormalizeDouble( SymbolInfoDouble( Symbol(), SYMBOL_ASK ), Digits() );
      stopLossPrice   = ( stopLoss == 0.0 ) ? 0.0 : NormalizeDouble( openPrice - stopLoss, Digits() );
      takeProfitPrice = ( takeProfit == 0.0 ) ? 0.0 : NormalizeDouble( openPrice + takeProfit, Digits() );
   }
   else if ( orderType == ORDER_TYPE_SELL ) {
      openPrice       = NormalizeDouble( SymbolInfoDouble( Symbol(), SYMBOL_BID ), Digits() );
      stopLossPrice   = ( stopLoss == 0.0 ) ? 0.0 : NormalizeDouble( openPrice + stopLoss, Digits() );
      takeProfitPrice = ( takeProfit == 0.0 ) ? 0.0 : NormalizeDouble( openPrice - takeProfit, Digits() );
   }
   else {
      //	This function only works with type buy or sell
      return ( -1 );
   }

   Trade.PositionOpen( Symbol(), orderType, InpOrderSize, openPrice, stopLossPrice, takeProfitPrice, InpTradeComment );

   return ( ( int )Trade.ResultOrder() );
}
