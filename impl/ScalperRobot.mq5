//+------------------------------------------------------------------+
//|                                                 ScalperRobot.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"

double entryPriceRobotScalper = 0;
BordersOperation bordersRobotScalper;
datetime startedDatetimeRobotScalper = 0;
bool nextCandleOnRobotScalper = false;
ResultOperation historyScalper;
int periodRobotScalper = 2;
bool dealAllowed = false;

/*
int OnInit(){
   startedDatetimeRobotScalper = TimeCurrent();
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
}
  
void OnTick() {
   if(verifyTimeToProtection()){
     startScalper(startedDatetimeRobotScalper);
   }
}

*/
ResultOperation startScalper(datetime startTime){
   if(hasNewCandle()){
      if(!hasPositionOpen()){ 
         //historyScalper = getHistory(getActualDay(startTime));
         int copiedPrice = CopyRates(_Symbol,_Period,0,periodRobotScalper,candles);
         if(copiedPrice == periodRobotScalper){
            bordersRobotScalper = drawBorders(candles[0].close, PONTUATION_ESTIMATE, PONTUATION_ESTIMATE);
            bordersRobotScalper.instantiated = true;
            dealAllowed = true;
         }
      }else{
         nextCandleOnRobotScalper = true;
      }
   }else{
      entryPriceRobotScalper = activeScalper(bordersRobotScalper.max, bordersRobotScalper.min, entryPriceRobotScalper);
   }
   
   return historyScalper;
}

double activeScalper(double maxBorder, double minBorder, double entryPrice){
   if(bordersRobotScalper.instantiated == true){
      MainCandles mainCandles = generateMainCandles();
      if(mainCandles.instantiated == true){
         double actualPrice = mainCandles.actual.close;
         ORIENTATION orient = MEDIUM;
         
         if(hasPositionOpen()){ 
            double entryDeal = PositionGetDouble(POSITION_PRICE_OPEN);
            double pontuation = MathAbs(entryPrice - actualPrice ) / _Point;  
            double tpPrice = PositionGetDouble(POSITION_TP); 
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
               if(entryPrice < actualPrice ){
                  entryPrice = actualPrice;
                  if(pontuation >= STOP_LOSS){
                     tradeLib.PositionModify(PositionGetTicket(0),entryPrice,tpPrice);
                 }
               }else{
                  closeRiskDeals(BUY, entryPrice, actualPrice);
               }
            }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){  
               if(entryPrice > actualPrice ){
                  entryPrice = actualPrice;
                 if(pontuation >= STOP_LOSS){
                     tradeLib.PositionModify(PositionGetTicket(0),entryPrice,tpPrice);
                  }
               }else{
                  closeRiskDeals(SELL, entryPrice, actualPrice);
               }
            }
         }else{
            if(dealAllowed){
               if(actualPrice >= maxBorder){
                  entryPrice = actualPrice;
                  orient = UP;
               }else if(actualPrice <= minBorder){
                  entryPrice = actualPrice;
                  orient = DOWN;
               }
               
               if(AGAINST_CURRENT == ON){
                  if(orient == DOWN){
                     orient = UP;
                  }else  if(orient == UP){
                     orient = DOWN;
                  }
               }
               
               bool hasResult = toBuyOrToSell(orient,ACTIVE_VOLUME,STOP_LOSS,TAKE_PROFIT); 
               if(hasResult){
                  Print("Negociação finalizada. ");
                  dealAllowed = false;
               }
            }
            
           /* if(dealAllowed){
               if(actualPrice >= maxBorder){
                  entryPrice = actualPrice;
                  orient = DOWN;
               }else if(actualPrice <= minBorder){
                  entryPrice = actualPrice;
                  orient = UP;
               }
               bool hasResult = toBuyOrToSell(orient,ACTIVE_VOLUME,STOP_LOSS,TAKE_PROFIT); 
               if(hasResult){
                  Print("Negociação finalizada. ");
                  dealAllowed = false;
               }
            }*/
          }
      }
   }
   return entryPrice;
}

void closeRiskDeals(TYPE_NEGOCIATION type, double entryPrice, double actualPrice){
   if(hasPositionOpen()){ 
      double entryDeal = PositionGetDouble(POSITION_PRICE_OPEN);
      double pontuation = MathAbs(entryPrice - actualPrice) / _Point;   
      int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
   
      if(type == BUY){
         if(nextCandleOnRobotScalper){
            if(candles[1].close <= candles[0].close){
               closeBuyOrSell(0);
               bordersRobotScalper.instantiated = false;
               nextCandleOnRobotScalper = false;
               dealAllowed = false;
            }
         }else if(entryDeal >= actualPrice){
            if(pontuation >= STOP_LOSS){
               closeBuyOrSell(0);
               bordersRobotScalper.instantiated = false;
               nextCandleOnRobotScalper = false;
               dealAllowed = false;
            }
         }
      }else{
         if(nextCandleOnRobotScalper){
            if(candles[1].close >= candles[0].close){
               closeBuyOrSell(0);
               bordersRobotScalper.instantiated = false;
               nextCandleOnRobotScalper = false;
               dealAllowed = false;
            }
         }
         else if(entryDeal <= actualPrice){
            if(pontuation >= STOP_LOSS || candles[1].close >= candles[0].close){
               closeBuyOrSell(0);
               bordersRobotScalper.instantiated = false;
               nextCandleOnRobotScalper = false;
               dealAllowed = false;
            }
         }
      }
   }else{
      bordersRobotScalper.instantiated = false;
      dealAllowed = false;
   }
}
     