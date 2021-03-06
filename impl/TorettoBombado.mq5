//+------------------------------------------------------------------+
//|                                                 TorettoRobot.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctions.mqh"

input int BARS_NUM = 3;

//input int PONTUATION_ESTIMATE 
input int ACTIVE_VOLUME = 1.0;
input double TAKE_PROFIT = 110;
input double STOP_LOSS = 40;

input int NUMBER_CONSECUTIVE_LOSSES_ALLOWED = 2;
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

bool activeBorders = false;
bool firstPositionStopMovel = false;
bool upVolume = false;

double lastAnalisedBar = 0;
ResultOperation resultDealsRobot;
double takeProfit = TAKE_PROFIT;
double stopLoss = STOP_LOSS;
int numConsecLosses = 0;
bool inverse = false;

TYPE_NEGOCIATION errors[10];

BordersOperation BordersOpRobot;

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
   if(trans.order_state == ORDER_STATE_FILLED){
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
   ORIENTATION orient;
   if(hasNewCandle()){
      int copied = CopyRates(_Symbol,_Period,0,3, candles);
      if(copied == 3){
         MqlRates actualCandle = candles[2];
         MqlRates decisionCandle = candles[1];
         MqlRates prevCandle = candles[0];
         if(hasPositionOpen()== true){
            activeBorders = false;
            firstPositionStopMovel =  activeStopMovel(prevCandle, decisionCandle, actualCandle, firstPositionStopMovel);
            //lastAnalisedBar = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
            //getHistory(0);
            //activeOpenEnd(prevCandle, actualCandle, decisionCandle);
         }else{ 
            int numBars = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
            if(numBars >= lastAnalisedBar + BARS_NUM){
               orient = avaliatePerPeriod();
               orient = decideToBuyOrToSell(orient);
               activeBorders = true;
            }
         }
      }
   }else{
      if(hasPositionOpen() == false && activeBorders == true){  
         TYPE_NEGOCIATION type = applyFilterPerBorders(orient);  
         if((type == BUY || type == SELL)){
            ORIENTATION newOrient = (type == BUY ? UP : DOWN);
            
            int volume = ACTIVE_VOLUME;
            if(upVolume == true){
               volume = 2 * volume;
            }
            bool hasResult = toBuyOrToSell(newOrient,volume,stopLoss,takeProfit);
            if(hasResult == true){
               Print("Realização negociada.");
               firstPositionStopMovel = true;
               activeBorders = false;
              // getHistory(0);
            }
         }
      }
   }
      
}

ORIENTATION avaliatePerPeriod(){
   if(hasPositionOpen()== false){
      int copied = CopyRates(_Symbol,_Period,0, BARS_NUM+2, candles);
      if(copied >= BARS_NUM){
         int up = 1, down = 1;
         for(int i = 0; i < BARS_NUM-1; i++){
            bool isHammer = MEDIUM;
           // double pointCandle = MathAbs(candles[i].open - candles[i].close) / _Point;
            
            // definir o minino de tamanho de vela pro candle ser analisado
            //if(pointCandle > 5){
               //definir se high e low é open ou close
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
         
         drawVerticalLine(firstCandle.time, nameStartLine, PERIOD_COLOR);
         drawVerticalLine(lastCandle.time, nameEndLine, PERIOD_COLOR);
         if(up >= nBars){
            drawHorizontalLine(lastCandle.high, firstCandle.time, nameBordLine, PERIOD_COLOR);
            return UP;
         }else if(down >= nBars){
            drawHorizontalLine(lastCandle.low, firstCandle.time, nameBordLine, PERIOD_COLOR);
            return DOWN;
         }else{
            //drawHorizontalLine(candles[BARS_NUM/2].close, firstCandle.time, nameBordLine, PERIOD_COLOR);
            return MEDIUM;
         }
      }
   }
   
   return MEDIUM;
}

ORIENTATION decideToBuyOrToSell(ORIENTATION orient){
   ORIENTATION definedOrientation = MEDIUM;
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
          int pontuation =  0;
         if(orient == DOWN){
            if(prevCandle.open > decisionCandle.open && prevCandle.close > decisionCandle.close ){
                  drawVerticalLine(actualTime, "FavorTendencia"+ IntegerToString(numBars), clrBlue);
                  definedOrientation = DOWN;
            }else{
               isHammer = verifyIfHammer(decisionCandle);
               if(isHammer == UP){
                 //Contra da tendencia
                  upVolume = true;
                  drawVerticalLine(actualTime, "ContraTendencia"+ IntegerToString(numBars), clrRed);
                  definedOrientation = UP;
               }
               definedOrientation = MEDIUM;
            }
         }else if(orient == UP){
            if(prevCandle.close < decisionCandle.close && prevCandle.open < decisionCandle.open){
               drawVerticalLine(actualTime, "FavorTendencia"+ IntegerToString(numBars), clrBlue);
               definedOrientation = UP;
            }else{
               isHammer = verifyIfHammer(decisionCandle);
               if(isHammer == DOWN){   //A favor da tendencia
                  upVolume = true;
                  drawVerticalLine(actualTime, "ContraTendencia"+ IntegerToString(numBars), clrRed);
                  definedOrientation = DOWN;
               }
               definedOrientation = MEDIUM;
            }
         }
      }
   }
   
   return definedOrientation;
}

ORIENTATION verifyIfHammer(MqlRates& candle){
   double maxAreaHammer = MathAbs(candle.high - candle.low);
   double head = MathAbs(candle.open - candle.close);
   double percMaxAreaHammer = maxAreaHammer * 0.55;
   datetime actualTime = candle.time;
   double stickH, stickL;
   
   if(head >= maxAreaHammer * 0.15){
      //drawVerticalLine(actualTime, "hammer-" + actualTime, HAMMER_COLOR); 
      if(verifyIfOpenBiggerThanClose(candle)){
         stickH = MathAbs(candle.high - candle.open);
         stickL = MathAbs(candle.low - candle.close);
      }else{
         stickH = MathAbs(candle.high - candle.close);
         stickL = MathAbs(candle.low - candle.open);
      }
         
      if(stickH > (stickL + head) && stickH >= percMaxAreaHammer){
         drawArrow(actualTime, "hammer-" + IntegerToString(actualTime), candle.close, DOWN); 
         return DOWN;
      }
      
      if(stickL > (stickH + head) && stickL >= percMaxAreaHammer){
         drawArrow(actualTime, "hammer-" + IntegerToString(actualTime), candle.close, UP); 
         return UP;
      }
   }
   
   return MEDIUM;
}

TYPE_NEGOCIATION applyFilterPerBorders(ORIENTATION orient){
   int copied = CopyRates(_Symbol,_Period,0, 3, candles);
   if(copied == 3){
      MqlRates  prevCandle = candles[0];
      MqlRates decisionCandle = candles[1];
      MqlRates actualCandle = candles[2];
      BordersOperation borders;
      
      if(orient == DOWN){
         borders = drawBorders(decisionCandle, 10, 60);
         if(borders.max > actualCandle.close &&  borders.min < actualCandle.close){
            Print("Atravessou a borda minima na compra.");
            return NONE;
         }else{
            return SELL;
         }
      }else if(orient == UP){
         borders = drawBorders(decisionCandle, 60, 10);
         if(borders.max > actualCandle.close &&  borders.min < actualCandle.close){
            Print("Atravessou a borda minima na venda.");
           return NONE;
         }else{
           return BUY;
         }
      }
   }
   
   return NONE;
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
      bool hasResult = false;
      double tpPrice = PositionGetDouble(POSITION_TP);
      if(errors[numConsecLosses-1] == BUY && errors[numConsecLosses] == BUY){
        
        tradeLib.PositionModify(PositionGetTicket(0),0, tpPrice);
           
        // hasResult = toBuyOrToSell(DOWN,ACTIVE_VOLUME,stopLoss,takeProfit);
      }else if(errors[numConsecLosses-1] == SELL && errors[numConsecLosses] == SELL){
      
        tradeLib.PositionModify(PositionGetTicket(0),0, tpPrice);
          // hasResult = toBuyOrToSell(UP,ACTIVE_VOLUME,stopLoss,takeProfit);
      }else{ 
         lastAnalisedBar = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT) - BARS_NUM + 1;
     
      }
      
      if(hasResult == true){
         firstPositionStopMovel = true;
      }
      
      errors[numConsecLosses-1] = NONE;
      errors[numConsecLosses] = NONE;
      numConsecLosses = 0;

    // lastAnalisedBar = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
    /*    ORIENTATION orient = avaliatePerPeriod();
        orient = decideToBuyOrToSell(orient);
        bool hasResult = toBuyOrToSell(orient,ACTIVE_VOLUME,stopLoss,takeProfit);
     
        if(hasResult == true){
            Print("Realização negociada.");
            firstPositionStopMovel = true;
            activeBorders = false;
           // getHistory(0);
        }
        if( inverse == true){
            lastAnalisedBar = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
            inverse = false;
            numConsecLosses = 0;
         }else{
           ORIENTATION orient = avaliatePerPeriod();
           orient = decideToBuyOrToSell(orient);
           bool hasResult = toBuyOrToSell(orient,ACTIVE_VOLUME,stopLoss,takeProfit);
        
           if(hasResult == true){
            inverse == true;
           }
         }
         /*
         if(trans.deal_type == DEAL_TYPE_BUY){
            toBuyOrToSell(DOWN,ACTIVE_VOLUME,stopLoss,takeProfit);
            inverse = true;
         }else if(trans.deal_type == DEAL_TYPE_SELL){
            toBuyOrToSell(UP,ACTIVE_VOLUME,stopLoss,takeProfit);
            inverse = true;
         } */
  //    numConsecLosses = 0;
   //   stopLoss = stopLoss * 5;
  }
}