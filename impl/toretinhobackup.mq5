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

//input int PONTUATION_ESTIMATE 

input int NUMBER_CONSECUTIVE_LOSSES_ALLOWED = 2;
input int PONTUATION_ESTIMATE = 100;
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
PeriodProtectionTime period;

bool moveStop = true;
bool openedDeal = false;

int numConsecLosses = 0;
int lastAnalisedBar = 0;
bool activeBorders = false;
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
   if(trans.order_state == ORDER_STATE_STARTED){
      Print("3213");
      openedDeal = true;
   }
   if(trans.order_state == ORDER_STATE_FILLED){
      openedDeal = false;
      double newTotal = calcTotal();
      if(resultDealsRobot.liquidResult != newTotal){
         double diff = newTotal - resultDealsRobot.liquidResult;
         bool isLoss = diff < 0;
         correctErrors(trans.order_type, isLoss);
         
         HistorySelect(0, TimeCurrent());
         ulong trades = HistoryDealsTotal();
         ResultOperation resultOperation = getResultOperation(diff);
         resultDealsRobot.liquidResult += resultOperation.liquidResult;
         resultDealsRobot.profitFactor += resultOperation.profitFactor;
         resultDealsRobot.profits += resultOperation.profits;
         resultDealsRobot.losses += resultOperation.losses;
         
         Comment("Trades: " + IntegerToString(trades), 
         " Profits: " + DoubleToString(resultDealsRobot.profits, 2), 
         " Losses: " + DoubleToString(resultDealsRobot.losses, 2), 
         " Profit Factor: " + DoubleToString(resultDealsRobot.profitFactor, 2), 
         " Liquid Result: " + DoubleToString(resultDealsRobot.liquidResult, 2));
      }
   }
   ResetLastError(); 
}

void startDeals(){
   ORIENTATION orient = MEDIUM;
   if(hasNewCandle()){
      int copied = CopyRates(_Symbol,_Period,0,3, candles);
      if(copied == 3){
         int numBars = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
         MqlRates actualCandle = candles[2];
         MqlRates decisionCandle = candles[1];
         MqlRates prevCandle = candles[0];
         if(hasPositionOpen()== true){
            activeBorders = false;
            entryPriceRobot =  activeStopMovel(prevCandle, decisionCandle, actualCandle, entryPriceRobot);
         }else{ 
            if(numBars >= lastAnalisedBar + BARS_NUM ){
               orient = avaliatePerPeriod();
               orient = decideToBuyOrToSell(orient);  
               if(orient == UP || orient == DOWN){
                  int volume = ACTIVE_VOLUME;
                  if(upVolume == true){
                    // volume = 2 * volume;
                  }
                  bool hasResult = toBuyOrToSell(orient,volume,STOP_LOSS,TAKE_PROFIT);
                  if(hasResult == true){
                     firstPositionStopMovel = true;
                     entryPriceRobot = 0;
                  }
               }
            }
         }
      }
   }else{
      if(hasPositionOpen() == false && activeBorders == true){  
        // applyFilterPerBorders(orient);  
      }
   }
      
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
         ObjectDelete(0,nameStartLine);
         ObjectDelete(0,nameBordLine);
         ObjectDelete(0,nameEndLine);
         
         averagePontuation.max += lastCandle.high;
         averagePontuation.min += lastCandle.low;
         averagePontuation.max = averagePontuation.max / BARS_NUM;
         averagePontuation.min = averagePontuation.min / BARS_NUM;
         drawVerticalLine(firstCandle.time, nameStartLine, PERIOD_COLOR);
         drawVerticalLine(lastCandle.time, nameEndLine, PERIOD_COLOR);
         double pontuationEstimate = (averagePontuation.max-averagePontuation.min) / _Point;
         if(up >= nBars ){
            if(pontuationEstimate >= PONTUATION_ESTIMATE ){
               drawHorizontalLine(lastCandle.high, firstCandle.time, nameBordLine, PERIOD_COLOR);
               return UP;
           }
         }else if(down >= nBars ){
            if(pontuationEstimate >= PONTUATION_ESTIMATE ){
               drawHorizontalLine(lastCandle.low, firstCandle.time, nameBordLine, PERIOD_COLOR);
               return DOWN;
           }
         }else{
            //drawHorizontalLine(candles[BARS_NUM/2].close, firstCandle.time, nameBordLine, PERIOD_COLOR);
            return MEDIUM;
         }
      }
   }
   
   return MEDIUM;
}

ORIENTATION decideToBuyOrToSell(ORIENTATION orient){
   int copied = CopyRates(_Symbol,_Period,0, 3, candles);
   if(copied == 3){
      MqlRates  prevCandle = candles[0];
      MqlRates decisionCandle = candles[1];
      datetime actualTime = decisionCandle.time;
      int numBars = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
      ORIENTATION isHammer = MEDIUM;
      BordersOperation borders;
      
      upVolume = false;
      if(orient != MEDIUM){
         if(orient == DOWN){
            isHammer = verifyIfHammer(decisionCandle);
            if(isHammer == UP){
               upVolume = true;
               drawVerticalLine(actualTime, "ContraTendencia"+ IntegerToString(numBars), clrRed);
               return UP;
            }else{
               if(prevCandle.open > decisionCandle.open && prevCandle.close > decisionCandle.close ){
                  drawVerticalLine(actualTime, "FavorTendencia"+ IntegerToString(numBars), clrBlue);
                  return DOWN;
               }
            }
         }else if(orient == UP){
            isHammer = verifyIfHammer(decisionCandle);
            if(isHammer == DOWN){   
               upVolume = true;
               drawVerticalLine(actualTime, "ContraTendencia"+ IntegerToString(numBars), clrRed);
               return DOWN;
            }else{
               if(prevCandle.close < decisionCandle.close && prevCandle.open < decisionCandle.open){
                  drawVerticalLine(actualTime, "FavorTendencia"+ IntegerToString(numBars), clrBlue);
                  return UP;
               }
            }
         }
      }
   }
   
   return MEDIUM;
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
         drawArrow(actualTime, "hammer-" + IntegerToString(actualTime), candle.close, DOWN); 
         return DOWN;
      }
   }else{
      if(head < maxHead || body > maxBody ){
         drawArrow(actualTime, "hammer-" + IntegerToString(actualTime), candle.close, UP); 
         return UP;
      }
   } 
   
   return MEDIUM;
}

void applyFilterPerBorders(ORIENTATION orient){
   ORIENTATION newOrient = MEDIUM;
   int copied = CopyRates(_Symbol,_Period,0, 3, candles);
   if(copied == 3){
      MqlRates  prevCandle = candles[0];
      MqlRates decisionCandle = candles[1];
      MqlRates actualCandle = candles[2];
      BordersOperation borders;
      
      double points = MathAbs(decisionCandle.close-decisionCandle.open) / _Point;
      if(orient == DOWN){
         borders = drawBorders(decisionCandle, points, 5);
         if(borders.max < actualCandle.close){
            activeBorders = false;
            newOrient = MEDIUM;
         }else{
            newOrient = DOWN;
         }
      }else if(orient == UP){
         borders = drawBorders(decisionCandle, 5, points);
         if(borders.min > actualCandle.close){
            activeBorders = false;
            newOrient = MEDIUM;
         }else{
           newOrient = UP;
         }
      }
      if(newOrient == UP || newOrient == DOWN){
         int volume = ACTIVE_VOLUME;
         if(upVolume == true){
            volume = 2 * volume;
         }
         bool hasResult = toBuyOrToSell(newOrient,volume,STOP_LOSS,TAKE_PROFIT);
         if(hasResult == true){
            Print("Realização negociada.");
            firstPositionStopMovel = true;
            activeBorders = false;
         }
      }
   }
}


void correctErrors(ENUM_ORDER_TYPE orderType, bool isLoss){
   if(isLoss == false){
      numConsecLosses = 0;
      errors[numConsecLosses] = NONE;
   }else{
      if(orderType == ORDER_TYPE_BUY){
         errors[numConsecLosses] = BUY;
      }else if(orderType == ORDER_TYPE_SELL){
         errors[numConsecLosses] = SELL;
      }
      numConsecLosses++;
  }
   
   //Se receber uma quantidade de perdas consecutivas espera um novo periodo
   if(numConsecLosses >= NUMBER_CONSECUTIVE_LOSSES_ALLOWED){
     //lastAnalisedBar = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT) - BARS_NUM + 3 ;
     /* bool hasResult = false;
   
      
         if(orderType == DEAL_TYPE_BUY){
            toBuyOrToSell(DOWN,ACTIVE_VOLUME,STOP_LOSS,TAKE_PROFIT);
         }else if(orderType == DEAL_TYPE_SELL){
            toBuyOrToSell(UP,ACTIVE_VOLUME,STOP_LOSS,TAKE_PROFIT);
         }
      */
      errors[numConsecLosses-1] = NONE;
      errors[numConsecLosses] = NONE;
      numConsecLosses = 0;
  }
}