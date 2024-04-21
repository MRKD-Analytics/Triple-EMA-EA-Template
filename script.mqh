


/*
   This file contains a script for a generic Triple EMA strategy. 
   
   Sends a BUY signal when EMAs are trending upwards,
   and a SELL signal when EMAs are trending downwards 
   
   DISCLAIMER: This script does not guarantee future profits, and is 
   created for demonstration purposes only. Do not use this script 
   with live funds. 
*/

/*
#include <B63/Generic.mqh> 
#include "trade_ops.mqh"
*/ 
#include <utilities/Utilities.mqh> 
#include <utilities/TradeOps.mqh> 

enum TradeSignal { Long, Short, None }; 

input int      InpMagic       = 111111; // Magic Number
input int      InpEmaOne      = 9; 
input int      InpEmaTwo      = 21; 
input int      InpEmaThree    = 55; 


class CEmaTrade : public CTradeOps {
private:
            int      ema_one_, ema_two_, ema_three_; 
public: 
   CEmaTrade();
   ~CEmaTrade() {}
            
            void        Stage();
            TradeSignal Signal(); 
            int         SendOrder(TradeSignal signal); 
            int         ClosePositions(ENUM_ORDER_TYPE order_type); 
            bool        DeadlineReached(); 
            
            double      EmaOneValue();
            double      EmaTwoValue(); 
            double      EmaThreeValue(); 
   
}; 

CEmaTrade::CEmaTrade() 
   : CTradeOps(Symbol(), InpMagic)
   , ema_one_ (InpEmaOne)
   , ema_two_ (InpEmaTwo)
   , ema_three_ (InpEmaThree) {}
   
   
double      CEmaTrade::EmaOneValue()   { return iMA(Symbol(), PERIOD_CURRENT, ema_one_, 0, MODE_EMA, PRICE_CLOSE, 1); }
double      CEmaTrade::EmaTwoValue()   { return iMA(Symbol(), PERIOD_CURRENT, ema_two_, 0, MODE_EMA, PRICE_CLOSE, 1); }
double      CEmaTrade::EmaThreeValue() { return iMA(Symbol(), PERIOD_CURRENT, ema_three_, 0, MODE_EMA, PRICE_CLOSE, 1); }

bool        CEmaTrade::DeadlineReached() { return UTIL_TIME_HOUR(TimeCurrent()) >= 20; }

TradeSignal CEmaTrade::Signal() {
   double ema_one_value = EmaOneValue();
   double ema_two_value = EmaTwoValue();
   double ema_three_value = EmaThreeValue(); 
   
   if (ema_one_value > ema_two_value && ema_two_value > ema_three_value) return Long; 
   if (ema_one_value < ema_two_value && ema_two_value < ema_three_value) return Short; 
   return None; 
}

int         CEmaTrade::SendOrder(TradeSignal signal) {
   ENUM_ORDER_TYPE order_type; 
   double entry_price; 
   
   switch(signal) {
      case Long:
         order_type = ORDER_TYPE_BUY;
         entry_price = UTIL_PRICE_ASK();
         OP_OrdersCloseBatchOrderType(ORDER_TYPE_SELL); 
         break; 
      case Short:
         order_type = ORDER_TYPE_SELL;
         entry_price = UTIL_PRICE_BID(); 
         OP_OrdersCloseBatchOrderType(ORDER_TYPE_BUY); 
         break; 
      case None:
         return -1; 
      default:
         return -1;      
   }
   return OP_OrderOpen(Symbol(), order_type, 0.01, entry_price, 0, 0, NULL); 
}

void        CEmaTrade::Stage() {
   if (DeadlineReached()) {
      OP_OrdersCloseBatchOrderType(ORDER_TYPE_SELL);
      OP_OrdersCloseBatchOrderType(ORDER_TYPE_BUY); 
      return; 
   }
   
   TradeSignal signal = Signal();
   if (signal == None) return; 
   
   SendOrder(signal); 
}


CEmaTrade ema_trade; 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if (UTIL_IS_NEW_CANDLE()) {
      ema_trade.Stage(); 
   }
   
  }
//+------------------------------------------------------------------+
