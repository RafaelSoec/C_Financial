//+------------------------------------------------------------------+
//|                                                        Media.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property indicator_color1  Yellow
#property version   "1.00"

input string TIME_TO_START_AVALIATION = "10:30";

#include "MainFunctionBackup.mqh"

//input double INIT_POINT = 0;

double channelSize = PONTUATION_ESTIMATE;
double initPointMacro = 0;
double endPointMacro = 0;

double averageML[], averageMH[], averageMD[];
int handleMh, handleMl, handleMd;

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
     //handleMh = iCustom(_Symbol, PERIOD_CURRENT,"Custom Moving Average",1, 0,MODE_SMA, PRICE_CLOSE);
    // handleMh = iMA(_Symbol,PERIOD_CURRENT,1,0,MODE_SMA,PRICE_CLOSE);
     handleMl = iMA(_Symbol,PERIOD_CURRENT,5,0,MODE_SMA,PRICE_CLOSE);
     handleMd = iMA(_Symbol,PERIOD_CURRENT,15,0,MODE_SMA,PRICE_CLOSE);
     //handleMl = iMA(_Symbol,PERIOD_H1,1,0,MODE_SMA,PRICE_CLOSE);
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

                  if(CopyBuffer(handleMd,0,0,1,averageMD) == 1 && CopyBuffer(handleMl,0,0,1,averageML) == 1 && CopyBuffer(handleMh,0,0,1,averageMH) == 1){
                     Print("t");
                  }
   /*
  if(verifyTimeToProtection()){
      int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
      if(copiedPrice == 2){
         if(isPossibleStartDeals(candles[1].close)){
            if(hasNewCandle()){
               waitNewCandleMacro--;
            }else{
               if(waitNewCandleMacro <= 0){
                  if(hasPositionOpen()){
                   //  PlaySound("sounds/smb_gameover.wav");
                     //valueDealEntryPriceMacro = activeStopMovel(valueDealEntryPriceMacro, candles[1]);
                  }else{
                     if(!crossOverBorderMacro){
                        orientationMacroRobot = recoverOrientation(candles[1].close);
                       // decideToBuyOrSellMacroRobot(orientationMacroRobot, candles[0], candles[1].close);
                     }
                  }
               }
            }
        }
      }
  }else{
      closeBuyOrSell(0);
  }*/
}

void decideToBuyOrSellMacroRobot(ORIENTATION orient, MqlRates& candle, double closePrice){
      
   if(orient != MEDIUM ){
      if(hasPositionOpen() == false){ 
         double neededPoints = 0;
         datetime actualTime = TimeCurrent();
         if(orient == UP){
            neededPoints = (initPointMacro + (channelSize * _Point));
            if( closePrice > neededPoints){
               crossOverBorderMacro = true;
              // PlaySound("sounds/smb_world_clear.wav");
               toBuyOrToSellMediaRobot(orient, calcPoints(candle.low, closePrice), TAKE_PROFIT);
            }
         }else if(orient == DOWN){
            neededPoints = (endPointMacro - (channelSize * _Point));
            if( closePrice < neededPoints){
               crossOverBorderMacro = true;
              // PlaySound("sounds/smb_world_clear.wav");
               toBuyOrToSellMediaRobot(orient, calcPoints(candle.high, closePrice), TAKE_PROFIT);
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
         
         double midPoints = calcPoints(initPointMacro, endPointMacro) * 0.25;
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
   }
   
   return (initPointMacro != 0 && endPointMacro != 0);
}

void toBuyOrToSellMediaRobot(ORIENTATION orient, double stopLoss, double takeProfit){
  toBuyOrToSell(orient,ACTIVE_VOLUME,stopLoss,takeProfit);
  if(verifyResultTrade()){
     valueDealEntryPriceMacro = 0;
     waitNewCandleMacro = 1;
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

    