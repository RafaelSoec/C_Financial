//+------------------------------------------------------------------+
//|                                                        Media.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

input string TIME_TO_START_AVALIATION = "10:30";

#include "MainFunctionBackup.mqh"

//input double INIT_POINT = 0;

double channelSize = PONTUATION_ESTIMATE;
double initPointMacro = 0;
double endPointMacro = 0;

BordersOperation bordersSupportAndResistanceMacro;
ORIENTATION orientationMacroRobot = MEDIUM;
datetime startedDatetimeMacroRobot = 0;
ResultOperation resultDealsRobotMedia;
double valueDealEntryPriceMacro = 0;
bool crossOverBorderMacro = false;
int waitNewCandleMacro = 0;
int lastDayMediaRobot = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
     resultDealsRobotMedia.total = 0;
     startedDatetimeMacroRobot = TimeCurrent();
     drawVerticalLine(startedDatetimeMacroRobot, "start day", clrRed);
     bordersSupportAndResistanceMacro.max = 0;
     bordersSupportAndResistanceMacro.min = 1000;
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
void OnTick(){
   
  if(verifyTimeToProtection()){
      int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
      if(copiedPrice == 2){
         if(isPossibleStartDeals(candles[1].close)){
            if(hasNewCandle()){
               waitNewCandleMacro--;
            }else{
               if(waitNewCandleMacro <= 0){
                  if(hasPositionOpen() == false){
                     if(!crossOverBorderMacro){
                        orientationMacroRobot = recoverOrientation(candles[1].close);
                        decideToBuyOrSellMacroRobot(orientationMacroRobot, candles[1].close);
                     }
                  }else{
                     activeStopMovelPerPointsMacroRobot(candles[1]);
                  }
               }
            }
        }
      }
  }else{
      closeBuyOrSell(0);
  }
}

void decideToBuyOrSellMacroRobot(ORIENTATION orient, double closePrice){
      
   if(orient != MEDIUM ){
      if(hasPositionOpen() == false){ 
         double neededPoints = 0;
         if(orient == UP){
            neededPoints = (initPointMacro + (channelSize * _Point));
            if( closePrice > neededPoints){
               toBuyOrToSellMediaRobot(orient, calcPoints(initPointMacro, endPointMacro), TAKE_PROFIT);
            }
         }else if(orient == DOWN){
            neededPoints = (endPointMacro - (channelSize * _Point));
            if( closePrice < neededPoints){
               toBuyOrToSellMediaRobot(orient, calcPoints(initPointMacro, endPointMacro), TAKE_PROFIT);
            }
         }
      }
   }
}

bool isPossibleStartDeals(double closePrice){
   if(isNewDay(startedDatetimeMacroRobot)){
      startedDatetimeMacroRobot = TimeCurrent();
      drawVerticalLine(startedDatetimeMacroRobot, "start day" + TimeToString(startedDatetimeMacroRobot), clrRed);
      bordersSupportAndResistanceMacro.min = 1000;
      bordersSupportAndResistanceMacro.max = 0;
      crossOverBorderMacro = false;
      initPointMacro = 0;
      endPointMacro = 0;
   }
   
   if(initPointMacro == 0 || endPointMacro == 0){
      // verificar se ja existe a borda de suporte
      datetime timeLocal = TimeCurrent();
      datetime start = StringToTime(TIME_TO_START_AVALIATION);
      if(timeLocal > start){
         initPointMacro = bordersSupportAndResistanceMacro.max;
         endPointMacro = bordersSupportAndResistanceMacro.min;
         drawHorizontalLine(endPointMacro, TimeCurrent(), "support border", clrYellow);
         drawHorizontalLine(initPointMacro, TimeCurrent(), "resistance border", clrYellow);
         
         double midPoints = calcPoints(initPointMacro, endPointMacro) / 2;
         if(midPoints < PONTUATION_ESTIMATE){
            channelSize = midPoints;
         }
      }else{
         if(closePrice >  bordersSupportAndResistanceMacro.max){
            bordersSupportAndResistanceMacro.max = closePrice;
         }else if(closePrice <  bordersSupportAndResistanceMacro.min){
            bordersSupportAndResistanceMacro.min = closePrice;
         }
      }
      /*double points = calcPoints(closePrice, initPointMacro);
      if(points > PONTUATION_ESTIMATE){
         endPointMacro = closePrice;
         drawHorizontalLine(endPointMacro, TimeCurrent(), "support border", clrRed);
      }*/
   }
   
   return (initPointMacro != 0 && endPointMacro != 0);
}

void toBuyOrToSellMediaRobot(ORIENTATION orient, double stopLoss, double takeProfit){
  toBuyOrToSell(orient,ACTIVE_VOLUME,stopLoss,takeProfit);
  if(verifyResultTrade()){
     valueDealEntryPriceMacro = 0;
     waitNewCandleMacro = 0;
  }
}

ORIENTATION recoverOrientation(double closePrice){
   if(closePrice > initPointMacro){
      return UP;
   }else if(closePrice < endPointMacro){
      return DOWN;
   }
   
   return MEDIUM;
}

void  activeStopMovelPerPointsMacroRobot(MqlRates& candle){
   double newSlPrice = 0;
   double points = 0;
   if(hasPositionOpen()){ 
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      
      if(valueDealEntryPriceMacro <= 0 ){
         valueDealEntryPriceMacro = entryPrice;
      }
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
         if(candle.close > valueDealEntryPriceMacro ){
            valueDealEntryPriceMacro = candle.close;
            initPointMacro = candle.close;
         }else{
            points = calcPoints(valueDealEntryPriceMacro, candle.close);
            if(points > channelSize && verifyIfOpenBiggerThanClose(candle)){
               closeBuyOrSell(0);
               crossOverBorderMacro = true;
            }
         }
      }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
         if(candle.close < valueDealEntryPriceMacro ){
            valueDealEntryPriceMacro = candle.close;
            endPointMacro = candle.close;
         }else{
            points = calcPoints(valueDealEntryPriceMacro, candle.close);
            if(points > channelSize && !verifyIfOpenBiggerThanClose(candle)){
               closeBuyOrSell(0);
               crossOverBorderMacro = true;
            }
         }
      }
   }
}
    