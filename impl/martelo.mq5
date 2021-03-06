//+------------------------------------------------------------------+
//|                                                 TorettoRobot.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"

input int BARS_NUM = 5;

input color HAMMER_COLOR = clrViolet;
input color PERIOD_COLOR = clrGreenYellow;
//input color PERIOD_COLOR_UP = clrBlue;
//input color PERIOD_COLOR_DOWN = clrYellow;

bool upVolume = false;

/*
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   createButton("BotaoPanic", WIDTH_BUTTON_PANIC, HEIGHT_BUTTON_PANIC, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Negociacoes", clrWhite, clrRed, clrRed, false);
   period.dealsLimitProtection = DEALS_LIMIT_TIME;
   period.startProtection = START_PROTECTION_TIME;
   period.endProtection = END_PROTECTION_TIME;
  
   startRobots();
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   finishRobots();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(BARS_NUM < 2){
      Alert("O numero de barras analisadas deve ser maior que 3");
   }else{
      if(verifyTimeToProtection(period)){
         startDeals();
      }
   }
   
  }
//+------------------------------------------------------------------+

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
//---
   // Fechar negociacões
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "BotaoPanic"){
         removeDeals();
         Alert("Negociações finalizadas");
      }
   }
}
void OnTradeTransaction(const MqlTradeTransaction & trans,
                        const MqlTradeRequest & request,
                        const MqlTradeResult & result)
  {
   ResetLastError(); 
}*/

void startDeals(){
   if(hasNewCandle()){
      int copied = CopyRates(_Symbol,_Period,0,2, candles);
      if(copied == 2){
            verifyIfHammer(candles[0]);
       }
    }
  }
  
ORIENTATION verifyIfHammer(MqlRates& candle){
   double maxAreaHammer = MathAbs(candle.high - candle.low);
   double maxHead =  maxAreaHammer * 0.3;
   double maxBody =  maxAreaHammer * 0.65;
   datetime actualTime = candle.time;
   double stickH, stickL, head, body;
   
      //drawVerticalLine(actualTime, "hammer-" + actualTime, HAMMER_COLOR); 
   if(verifyIfOpenBiggerThanClose(candle)){
      stickH = MathAbs(candle.high - candle.open);
      stickL = MathAbs(candle.low - candle.close);
      head = MathAbs(candle.high - candle.close);
      body = MathAbs(candle.low - candle.close);
   }else{
      stickH = MathAbs(candle.high - candle.close);
      stickL = MathAbs(candle.low - candle.open);
      head = MathAbs(candle.high - candle.open);
      body = MathAbs(candle.low - candle.open);
   }
      
   if(stickH > stickL){      
      if(head < maxHead || body > maxBody){
         drawArrow(actualTime, "hammer-" + IntegerToString(actualTime), candle.close, DOWN, clrRed); 
         return DOWN;
      }
   }else{
      if(head < maxHead || body > maxBody ){
         drawArrow(actualTime, "hammer-" + IntegerToString(actualTime), candle.close, UP, clrRed); 
         return UP;
      }
   } 
   
   return MEDIUM;
}
