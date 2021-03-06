//+------------------------------------------------------------------+
//|                                                MacroAnalisys.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


#include "MainFunctionBackup.mqh"

double averageJAW[], averageTEETH[], averageLIPS[], averageFrac[], upperFractal[], lowerFractal[], CCI[], valuePrice = 0;
int teeth, jaw, lips, handleFractal, fractMedia, handleICCI, countAverage = 0;
ORIENTATION orientMacro = MEDIUM;
BordersOperation bordersFractal;
bool waitCloseJaw = false;
int periodAval = 3;
//+------------------------------------------------------------------+
//                                                                          | Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      
      jaw = iMA(_Symbol,PERIOD_CURRENT,13,8,MODE_SMMA,PRICE_MEDIAN);
      teeth = iMA(_Symbol,PERIOD_CURRENT,8,5,MODE_SMMA,PRICE_MEDIAN);
      lips = iMA(_Symbol,PERIOD_CURRENT,5,3,MODE_SMMA,PRICE_MEDIAN);
      fractMedia = iFrAMA(_Symbol,PERIOD_CURRENT,1,0,PRICE_MEDIAN);
      handleICCI = iCCI(_Symbol,PERIOD_CURRENT,14,PRICE_TYPICAL);
      handleFractal = iFractals(_Symbol, _Period);

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
   if(verifyTimeToProtection()){
      int copiedPrice = CopyRates(_Symbol,_Period,0,3,candles);
      if(copiedPrice == 3){
         if(hasNewCandle()){
            if(CopyBuffer(jaw,0,0,periodAval,averageJAW) == periodAval && 
               CopyBuffer(lips,0,0,periodAval,averageLIPS) == periodAval && 
               CopyBuffer(teeth,0,0,periodAval,averageTEETH) == periodAval && 
               CopyBuffer(handleICCI,0,0,periodAval,CCI) == periodAval &&
               CopyBuffer(fractMedia,0,0,periodAval,averageFrac) == periodAval){
               if(hasPositionOpen() == false){
                  double closePrice = candles[2].close;
                  decisionAlligator(closePrice, averageFrac[0]);
                  /*if(orientMacro != MEDIUM && waitCloseJaw == true){
                     if(orientMacro == DOWN && averageLIPS[0] > averageJAW[0] && averageLIPS[periodAval-1] < averageJAW[periodAval-1]){
                        toBuyOrToSellAlligatorRobot(SELL, closePrice);
                     }else if(orientMacro == UP && averageLIPS[0] < averageJAW[0] && averageLIPS[periodAval-1] > averageJAW[periodAval-1]){
                        toBuyOrToSellAlligatorRobot(BUY, closePrice);
                     }
                  }*/
               }else{
                // valuePrice =  activeStopMovel(valuePrice, candles[periodAval-1]);
                activeStopMovelPerPoints(20);
                  /*BordersOperation borders = getActualsFractals();
                  double stopLoss = PositionGetDouble(POSITION_SL);
                  double takeProfit = PositionGetDouble(POSITION_TP);
                  double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){ 
                     if(borders.min != 0 && borders.min < entryPrice && borders.min < stopLoss){
                        tradeLib.PositionModify(PositionGetTicket(0), borders.min, takeProfit);
                     }else{
                        if(averageLIPS[0] > averageJAW[0] && averageLIPS[periodAval-1] > averageJAW[periodAval-1]){
                           closeBuyOrSell(0);
                        }
                     }
                  }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){ 
                     if(borders.max != 0 && borders.max > entryPrice && borders.max > stopLoss){
                        tradeLib.PositionModify(PositionGetTicket(0), borders.max, takeProfit);
                     }else{
                        if(averageLIPS[0] < averageJAW[0] && averageLIPS[periodAval-1] < averageJAW[periodAval-1]){
                           closeBuyOrSell(0);
                        }
                     }
                  }*/
               }
            }
         }
      }
   }else{
      closeBuyOrSell(0);
   }
//---
   
  }
  
BordersOperation getActualsFractals(){
   int periodFractal = 3;
   
   //ArraySetAsSeries(upperFractal, true);
   //ArraySetAsSeries(lowerFractal, true);
   if(CopyBuffer(handleFractal,UPPER_LINE, 0, periodFractal, upperFractal) == periodFractal && 
      CopyBuffer(handleFractal, LOWER_LINE, 0, periodFractal, lowerFractal) == periodFractal){
      if(lowerFractal[0] != EMPTY_VALUE){
         bordersFractal.min = lowerFractal[0];
      }
      if(upperFractal[0] != EMPTY_VALUE){
         bordersFractal.max= upperFractal[0];
      }
   }
   
   return bordersFractal;
}
  
  
void decisionAlligator(double closePrice, double averageFr){
   if(waitCloseJaw == false){
      //validar cruzamentos alligator
      if(averageLIPS[periodAval-1] < averageTEETH[periodAval-1] && 
         averageLIPS[periodAval-1] < averageJAW[periodAval-1] && 
         averageLIPS[0] > averageJAW[periodAval-1]  && 
         averageLIPS[0] > averageTEETH[periodAval-1]){
            if(CCI[periodAval-1] >= 100){
               toBuyOrToSellAlligatorRobot(SELL, closePrice, averageFr);
            }
          // waitCloseJaw = true;
            orientMacro = DOWN;
      }else if(averageLIPS[periodAval-1] > averageTEETH[periodAval-1] && 
         averageLIPS[periodAval-1] > averageJAW[periodAval-1] && 
         averageLIPS[0] < averageJAW[periodAval-1]  && 
         averageLIPS[0] < averageTEETH[periodAval-1]){ 
            if(CCI[periodAval-1] <= -100){
               toBuyOrToSellAlligatorRobot(BUY, closePrice, averageFr);
            }
          //  waitCloseJaw = true;
            orientMacro = UP;
      }else{
         orientMacro = MEDIUM;
      }
   }
}
void toBuyOrToSellAlligatorRobot(TYPE_NEGOCIATION type, double closePrice, double averageFr){
   BordersOperation borders = getActualsFractals();
   double stopLoss = STOP_LOSS,  takeProfit = TAKE_PROFIT, points;
   
/*  if(type == BUY && borders.max != 0){
      if(closePrice >= borders.max && closePrice > averageFr){
         points = calcPoints(closePrice, borders.max);
         if(points > stopLoss){
            stopLoss = points;
         }
         realizeDeals(type, ACTIVE_VOLUME, stopLoss, takeProfit);
      }
   }else if(type == SELL && borders.min != 0){
      if(closePrice <= borders.min && closePrice < averageFr){
         points = calcPoints(closePrice, borders.min);
         if(points > stopLoss){
            stopLoss = points;
         }
         realizeDeals(type, ACTIVE_VOLUME, stopLoss, takeProfit);
      }
   } */
   
   
   realizeDeals(type, ACTIVE_VOLUME, stopLoss, takeProfit);
   
   if(verifyResultTrade()){
      waitCloseJaw = false;
      valuePrice = closePrice;
   }
}

