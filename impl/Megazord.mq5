//+------------------------------------------------------------------+
//|                                                     Megazord.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"

input POWER AGAINST_CURRENT = OFF;

input int BARS_NUM = 5;

//input int PONTUATION_ESTIMATE 

input int NUMBER_CONSECUTIVE_LOSSES_ALLOWED = 2;
input int PONTUATION_ESTIMATE = 120;
//input POWER HIGH_OSCILATION = OFF;

input string DEALS_LIMIT_TIME = "17:30";
input string START_PROTECTION_TIME = "12:00";
input string END_PROTECTION_TIME = "13:00";

input int HEIGHT_BUTTON_PANIC = 350;
input int WIDTH_BUTTON_PANIC = 500;

input color HAMMER_COLOR = clrViolet;
input color PERIOD_COLOR = clrGreenYellow;
//input color PERIOD_COLOR_UP = clrBlue;
//input color PERIOD_COLOR_DOWN = clrYellow;

MqlRates lastDeal;
MqlRates candles[];
PeriodProtectionTime period;

bool moveStop = true;
bool openedDeal = false;

int numConsecLosses = 0;
int lastAnalisedBar = 0;
bool waitNewPeriod = false;
bool firstPositionStopMovel = false;
bool upVolume = false;
double newTotal = 0;
double total = 0;

TYPE_NEGOCIATION errors[10];
ResultOperation resultDealsRobot;
BordersOperation BordersOpRobot;

double entryPriceRobot = 0;

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
      ORIENTATION orient = verifyOrientation();
      decideToBuyOrSell(orient);   
   
  }
//+------------------------------------------------------------------+


ORIENTATION verifyOrientation(){
   if(hasNewCandle()){
      if(waitingNewPeriod()){
         return avaliatePeriods();
      }else{
         return closeRiskDeals();
      }
   }
   
   return MEDIUM;
}

bool waitingNewPeriod(){
   int numBars = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
   return numBars >= lastAnalisedBar + BARS_NUM;
}

ORIENTATION avaliatePeriods(){
   ulong numBars = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
   int barsPrevActualCandle = BARS_NUM - 1;
   int copied = CopyRates(_Symbol,_Period,0, BARS_NUM, candles);
   if(copied == BARS_NUM && barsPrevActualCandle > 0){
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
      averagePontuation.max = averagePontuation.max / BARS_NUM;
      averagePontuation.min = averagePontuation.min / BARS_NUM;
      
      datetime actualTime = TimeLocal();
      //int medium = barsPrevActualCandle / 2;
      int medium = BARS_NUM / 2;
      double pontuationEstimate = (averagePontuation.max-averagePontuation.min) / _Point;
      
      up = (up > 0 ? up : 0);
      down = (down > 0 ? down : 0);
      //int pontuationEstimate = 0;
      if(up-down >= medium){ 
         if(pontuationEstimate >= PONTUATION_ESTIMATE ){
            drawVerticalLine(actualTime, "up" + IntegerToString(numBars), clrYellow);
            lastAnalisedBar = numBars;
            return UP;
        }
      }else if(down-up >= medium){
         if(pontuationEstimate >= PONTUATION_ESTIMATE){
            drawVerticalLine(actualTime, "down" + IntegerToString(numBars), clrBlue);
            lastAnalisedBar = numBars;
            return DOWN;
         }
      }
   }
   return MEDIUM;
}

void decideToBuyOrSell(ORIENTATION orient){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   if(AGAINST_CURRENT == ON){
      if(typeDeal == BUY){
         typeDeal = SELL;            
      }
      else if(typeDeal == SELL){
         typeDeal = BUY;
      }   
   }
   
   
   realizeDeals(typeDeal, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT);
   //getHistory();
}

ORIENTATION closeRiskDeals(){
   for(int i = PositionsTotal()-1; i >= 0; i--){
      string symbol = PositionGetSymbol(i);
      if(_Symbol == symbol){
         // verifica se existe posicao aberta e qual tipo de tipo de posicao esta ativo
         MainCandles mainCandles = generateMainCandles();
         if(mainCandles.instantiated == true){
            bool up = false;
            double pontuationEstimateMin = (mainCandles.secondLast.low + mainCandles.last.low +  mainCandles.actual.low) / 3;
            double pontuationEstimateMax = (mainCandles.secondLast.high + mainCandles.last.high +  mainCandles.actual.high) / 3;
            double pontuationEstimate = (pontuationEstimateMax-pontuationEstimateMin) / _Point;
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
               //Sinal Subindo
               if((mainCandles.secondLast.low < mainCandles.last.low) &&  (mainCandles.last.low <  mainCandles.actual.low || mainCandles.last.low <  mainCandles.actual.open)){
                     Print("Ação -> COMPRA. O preço está subindo.");
                     //closeBuyOrSell();
                     return DOWN;
               }else{
                  Print("Sem a certeza de que o preço está subindo. Encerrando a compra.");
                  closeBuyOrSell();
               }
            }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
               //Sinal descendo
               if((mainCandles.secondLast.high > mainCandles.last.high) &&  (mainCandles.last.high >  mainCandles.actual.high || mainCandles.last.high >  mainCandles.actual.open)){
                     Print("Ação -> VENDA. O preço está descendo.");
                     //closeBuyOrSell();
                     return UP;
               }else{
                  Print("Sem a certeza de que o preço está descendo. Encerrando a venda.");
                  closeBuyOrSell();
               }
            }
         }
      }
   }
   
   return MEDIUM;
}

MainCandles generateMainCandles(){
   MainCandles mainCandles;
   int copiedPrice = CopyRates(_Symbol,_Period,0,3,candles);
   if(copiedPrice == 3){
      mainCandles.actual = candles[2];
      mainCandles.last = candles[1];
      mainCandles.secondLast = candles[0];
      mainCandles.instantiated = true;
   }else{
      mainCandles.instantiated = false;
   }
   
   return mainCandles;
}