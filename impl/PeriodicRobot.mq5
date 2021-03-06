//+------------------------------------------------------------------+
//|                                                PeriodicRobot.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"
#include "martelo.mq5"
#include "ScalperRobot.mq5"

datetime lastAnalisedBarPeriodicRobot = 0;
ORIENTATION lastOrientationPeriodicRobot = MEDIUM;
bool openDealNextCandlePeriodicRobot = false;
datetime startedDatetimePeriodicRobot = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   startedDatetimePeriodicRobot = TimeCurrent();
   
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
      startPeriodic(startedDatetimePeriodicRobot);
   
  }
//+------------------------------------------------------------------+

void startPeriodic(datetime startTime){
   if(hasNewCandle()){
      getHistory(getActualDay(startTime));
      if(!hasPositionOpen()){ 
         ORIENTATION newOrientation = verifyOrientation();
         //ORIENTATION newOrientation = avaliatePerPeriod();
         int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
         if(copiedPrice == 2){
            verifyIfHammer(candles[0]);
         }
         //startDealPeriodicRobot(newOrientation);
         /*   if(lastOrientationPeriodicRobot != MEDIUM && newOrientation != MEDIUM){
            //lastOrientationPeriodicRobot = MEDIUM;
            if(lastOrientationPeriodicRobot != newOrientation){
               startDealPeriodicRobot(newOrientation);
               lastOrientationPeriodicRobot = MEDIUM;
               //lastOrientationPeriodicRobot = newOrientation;
               //openDealNextCandlePeriodicRobot = true;
            }else{
               lastOrientationPeriodicRobot = newOrientation;
               bordersRobotScalper = drawBorders(candles[0].close, PONTUATION_ESTIMATE, PONTUATION_ESTIMATE);
               bordersRobotScalper.instantiated = true;
            }
         }else{
            lastOrientationPeriodicRobot = newOrientation;
         }
         */
      }
   }else{
     // entryPriceRobotScalper = activeScalper(bordersRobotScalper.max, bordersRobotScalper.min, entryPriceRobotScalper);
   }
}

void startDealPeriodicRobot(ORIENTATION newOrientation){
   datetime actualTime = TimeCurrent();
   ulong numBars = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
   drawVerticalLine(actualTime, "Decision" + IntegerToString(actualTime), clrYellow);
   bool hasResult = toBuyOrToSell(newOrientation,ACTIVE_VOLUME,STOP_LOSS,TAKE_PROFIT); 
   if(hasResult){
      //lastAnalisedBarPeriodicRobot = numBars;
      int copiedPrice = CopyRates(_Symbol,_Period,0,1,candles);
      if(copiedPrice == 1){
         verifyIfHammer(candles[0]);
        entryPriceRobotScalper = candles[0].close;
        bordersRobotScalper = drawBorders(candles[0].close, PONTUATION_ESTIMATE, PONTUATION_ESTIMATE);
        bordersRobotScalper.instantiated = true;
      }
   }
}

ORIENTATION verifyOrientation(){
   ulong numBars = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
   if(numBars >= lastAnalisedBarPeriodicRobot + PERIOD){
      int barsPrevActualCandle = PERIOD - 1;
      int copied = CopyRates(_Symbol,_Period,0, PERIOD, candles);
      if(copied == PERIOD && barsPrevActualCandle > 0){
         int up = 0, down = 0;
         MqlRates lastCandle = candles[barsPrevActualCandle], prevCandle, nextCandle;
         double maxPrice = candles[0].high, minPrice = candles[0].low;
         double prevHigh = 0, prevLow = 0, nextHigh = 0, nextLow = 0, secPrevLow = 0, secPrevHigh = 0;
         BordersOperation averagePontuation;
         averagePontuation.max = 0;
         averagePontuation.min = 0;
         
         for(int i = 0; i < barsPrevActualCandle; i++){
            prevCandle = candles[i];
            nextCandle = candles[i+1];
            averagePontuation.max += prevCandle.high;
            averagePontuation.min += prevCandle.low;
            if(i-1 >= 0){
               if(candles[i-1].open > candles[i-1].close){
                  secPrevHigh = MathAbs(candles[i-1].open + candles[i-1].high) / 2;
                  secPrevLow = MathAbs(candles[i-1].close + candles[i-1].low) / 2;
               }else{
                  secPrevLow =  MathAbs(candles[i-1].open + candles[i-1].low) / 2;
                  secPrevHigh = MathAbs(candles[i-1].close + candles[i-1].high) / 2;
               }
               
               if(secPrevHigh > prevHigh || secPrevLow > prevLow){
                  up--;
               }
               if(secPrevHigh < prevHigh || secPrevLow < prevLow){
                  down--;
               }
            }
            
            if(prevCandle.open > prevCandle.close){
               prevHigh = MathAbs(prevCandle.open + prevCandle.high) / 2;
               prevLow = MathAbs(prevCandle.close + prevCandle.low) / 2;
            }else{
               prevLow =  MathAbs(prevCandle.open + prevCandle.low) / 2;
               prevHigh = MathAbs(prevCandle.close + prevCandle.high) / 2;
            }
            
            if(nextCandle.open > nextCandle.close){
               nextHigh = MathAbs(nextCandle.open + nextCandle.high) / 2;
               nextLow = MathAbs(nextCandle.close + nextCandle.low) / 2;
               //nextHigh = MathAbs( nextCandle.high);
               //nextLow = MathAbs(nextCandle.low);
            }else{
               nextLow = MathAbs(nextCandle.open + nextCandle.low) / 2;
               nextHigh = MathAbs(nextCandle.close + nextCandle.high) / 2;
               //nextLow = MathAbs(nextCandle.low);
               //nextHigh = MathAbs(nextCandle.high);
            }
            
            //O sinal está subindo
            if(prevHigh <= nextHigh && prevLow <= nextLow){
               up++;
            }
            
            //O sinal está descendo
            if(prevHigh >= nextHigh && prevLow >= nextLow){
               down++;
            }
            
            if(prevCandle.high > maxPrice){
               maxPrice = prevCandle.high;
            }
            
            if(prevCandle.low < minPrice){
               minPrice = prevCandle.low;
            }
         }
         averagePontuation.max += lastCandle.high;
         averagePontuation.min += lastCandle.low;
         averagePontuation.max = averagePontuation.max / PERIOD;
         averagePontuation.min = averagePontuation.min / PERIOD;
         
         datetime actualTime = TimeLocal();
         //int medium = barsPrevActualCandle / 2;
         int medium = PERIOD / 2;
         double pontuationEstimate = (averagePontuation.max-averagePontuation.min) / _Point;
         
         up = (up > 0 ? up : 0);
         down = (down > 0 ? down : 0);
         //int pontuationEstimate = 0;
         if(up-down >= medium ){ 
            if(pontuationEstimate >= PONTUATION_ESTIMATE ){
               //drawArrow(actualTime, "up-" + IntegerToString(numBars), lastCandle.close, UP, clrRed); 
               drawVerticalLine(actualTime, "up" + IntegerToString(numBars), clrYellow);
               return UP;
           }
         }else if(down-up >= medium){
            if(pontuationEstimate >= PONTUATION_ESTIMATE){
              // drawArrow(actualTime, "down-" + IntegerToString(numBars), lastCandle.close, DOWN, clrRed); 
               drawVerticalLine(actualTime, "down" + IntegerToString(numBars), clrBlue);
               return DOWN;
            }
         }
      }
   }
   
   return MEDIUM;
}



ORIENTATION avaliatePerPeriod(){
   if(hasPositionOpen()== false){
      int copied = CopyRates(_Symbol,_Period,0, BARS_NUM+2, candles);
      if(copied >= BARS_NUM){
         BordersOperation averagePontuation;
         averagePontuation.max = 0;
         averagePontuation.min = 0;
         int up = 1, down = 1;
         for(int i = 0; i < BARS_NUM-1; i++){
               //definir se high e low é open ou close
               averagePontuation.max += candles[i].high;
               averagePontuation.min += candles[i].low;
               if(verifyIfOpenBiggerThanClose(candles[i])){
                  //descida
                  if(candles[i].open > candles[i+1].open && candles[i].close > candles[i+1].close){
                     down++;
                  }
                  //subida
                  else if(candles[i].open < candles[i+1].open && candles[i].close < candles[i+1].close){
                     up++;
                  }
               }else{
                  //descida
                  if(candles[i].close > candles[i+1].close && candles[i].open > candles[i+1].open){
                     down++;
                  }
                  //subida
                  else if(candles[i].close < candles[i+1].close && candles[i].open < candles[i+1].open){
                     up++;
                  }
               }
             //}
         }
         
         int nBars = BARS_NUM;      
         string nameStartLine = "period-start";
         string nameEndLine = "period-end";
         string nameBordLine = "period-border";
         MqlRates lastCandle = candles[BARS_NUM-1];
         MqlRates firstCandle = candles[0];
         //ObjectDelete(0,nameStartLine);
         //ObjectDelete(0,nameBordLine);
         //ObjectDelete(0,nameEndLine);
         
         averagePontuation.max += lastCandle.high;
         averagePontuation.min += lastCandle.low;
         averagePontuation.max = averagePontuation.max / BARS_NUM;
         averagePontuation.min = averagePontuation.min / BARS_NUM;
         //drawVerticalLine(firstCandle.time, nameStartLine, PERIOD_COLOR);
        // drawVerticalLine(lastCandle.time, nameEndLine, PERIOD_COLOR);
         double pontuationEstimate = (averagePontuation.max-averagePontuation.min) / _Point;
         if(up >= nBars ){
            //if(pontuationEstimate >= PONTUATION_ESTIMATE ){
               drawVerticalLine(TimeCurrent(), "up" + IntegerToString(TimeCurrent()), clrYellow);
               //drawHorizontalLine(lastCandle.high, TimeCurrent(), nameBordLine, PERIOD_COLOR);
               return UP;
           //}
         }else if(down >= nBars ){
            //if(pontuationEstimate >= PONTUATION_ESTIMATE ){
               drawVerticalLine(TimeCurrent(), "up" + IntegerToString(TimeCurrent()), clrYellow);
               //drawHorizontalLine(lastCandle.low, TimeCurrent(), nameBordLine, PERIOD_COLOR);
               return DOWN;
           //}
         }else{
            //drawHorizontalLine(candles[BARS_NUM/2].close, firstCandle.time, nameBordLine, PERIOD_COLOR);
            return MEDIUM;
         }
      }
   }
   
   return MEDIUM;
}