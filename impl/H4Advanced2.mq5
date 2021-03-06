#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"



#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>https://github.com/RafaelSoec/C_Financial

CPositionInfo  tradePosition;                   // trade position object
CTrade tradeLib;

enum TYPE_CANDLE{
   WEAK,
   STRONG,
   HAMMER,
   UNDECIDED,
};

enum OPERATOR{
   EQUAL,
   MAJOR,
   MINOR
};

enum ORIENTATION{
   UP,
   DOWN,
   MEDIUM
};

enum POSITION_GRAPHIC{
   BOTTOM,
   TOP,
   CENTER
};

enum TYPE_NEGOCIATION{
   BUY,
   SELL,
   NONE
};

enum POWER{
   ON,
   OFF
};

enum COORDINATE{
   HORIZONTAL,
   VERTICAL
};

struct CandleInfo {
   ORIENTATION orientation;
   TYPE_CANDLE type;
   double close;
   double open;
   double high;
   double low;
};

struct ResultOperation {
   double total;
   double profits;
   double losses;
   double liquidResult;
   double profitFactor;
   bool instantiated;
};

struct MainCandles {
   MqlRates actual;
   MqlRates last;
   MqlRates secondLast;
   bool instantiated;
};


struct BordersOperation {
   double max;
   double min;
   double central;
   bool instantiated;
   ORIENTATION orientation;
};

struct PeriodProtectionTime {
   string dealsLimitProtection;
   string endProtection;
   string startProtection;
   bool instantiated;
};

input POWER  IN_FAVOR = ON;
input POWER  EXPONENTIAL_ROBOTS = ON;
input POWER  ACTIVE_MOVE_TAKE = ON;
input POWER  ACTIVE_MOVE_STOP = ON;
input double PERCENT_MOVE = 40;
input double PONTUATION_MOVE_STOP = 800;
input double ACTIVE_VOLUME = 0.01;
input string CLOSING_TIME = "23:00";
input ulong MAGIC_NUMBER = 3232131231231231;
input int NUMBER_ROBOTS = 2;
input int NUMBER_MAX_ROBOTS = 300;
input int COUNT_TICKS = 40;
input double TAKE_PROFIT = 100;
input double STOP_LOSS = 100;

POWER USE_MAGIC_NUMBER = ON;
double PONTUATION_ESTIMATE = 500;
int NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;

MqlRates candles[];
datetime actualDay = 0;
bool negociationActive = false;
MqlTick tick;                // variável para armazenar ticks 

ORIENTATION orientMacro = MEDIUM;
int periodAval = 4, countRobots = 0, countTicks = 0, countCandles = 0;
bool waitNewCandle = false;
ulong robots[];

MqlRates candleMacro;
double averages[], averages8[], averages20[], averages80[], averages200[], MACD[], MACD5[], CCI[], FI[], VOL[], pointsMacro = 0;
double upperBand[], middleBand[], lowerBand[], upperBand5[], middleBand5[], lowerBand5[], RVI1[], RVI2[], RSI[];
int handleaverages[5], handleBand[2] ,handleICCI, handleVol[2], handleMACD[2], handleIRVI, handleFI, handleIRSI;

int BALANCE_ACTIVE = 0, MULTIPLIER_ROBOTS = 1, INITIAL_BALANCE;
ORIENTATION bestOrientation = MEDIUM;

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
//---
   // Fechar negociacões
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "BotaoPanic"){
         int pos = PositionsTotal() - 1;
         for(int i = pos; i >= 0; i--)  {
            if(hasPositionOpen(i)){
               ulong ticket = PositionGetTicket(i);
               PositionSelectByTicket(ticket);
               ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
               if(verifyMagicNumber(i, magicNumber)){
                     closeBuyOrSell(i);
               }
            }
         }
      }
   }
}

int OnInit(){

      createButton("BotaoPanic", 150, 400, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Negociacoes", clrWhite, clrRed, clrRed, false);
   
      handleICCI = iCCI(_Symbol,PERIOD_CURRENT,14,PRICE_TYPICAL);
      handleaverages[0] = iMA(_Symbol,PERIOD_H4, 8, 0, MODE_SMA, PRICE_CLOSE);
      handleaverages[1] = iMA(_Symbol,PERIOD_H4, 20, 0, MODE_SMA, PRICE_CLOSE);
      handleaverages[2] = iMA(_Symbol,PERIOD_H4, 80, 0, MODE_SMA, PRICE_CLOSE);
      handleaverages[3] = iMA(_Symbol,PERIOD_H4, 200, 0, MODE_SMA, PRICE_CLOSE);
      handleVol[0] = iVolumes(_Symbol,PERIOD_H4,VOLUME_TICK);
      BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
      INITIAL_BALANCE = BALANCE_ACTIVE;
     // handleIRVI = iRVI(_Symbol,PERIOD_H4,3);
     // handleCCI[0] = iCCI(_Symbol,PERIOD_H4,14,PRICE_TYPICAL);
     // handleFI = iForce(_Symbol,PERIOD_H4,14,MODE_SMA,VOLUME_TICK);
      updateNumberRobots();
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
   int copiedPrice = CopyRates(_Symbol,_Period,0,periodAval,candles);
   if(copiedPrice == periodAval){
      double spread = candles[periodAval-1].spread;
      if(hasNewCandle()){
         waitNewCandle = false;
         countCandles--;
      }else{
         Print("Robo executando");
         if(countTicks > COUNT_TICKS){
             updateNumberRobots();
             toNegociate(spread);
             
             //}
           //if(!waitNewCandle){
            //}
            moveAllPositions(spread);
            countTicks = 0;
         }
         countTicks++;
      }
   }
}

void updateNumberRobots(){
   if(EXPONENTIAL_ROBOTS == ON){  
      double profit = AccountInfoDouble(ACCOUNT_PROFIT);
      if(profit > BALANCE_ACTIVE * ACTIVE_VOLUME){
         if(NUMBER_MAX_ROBOTS > NUMBER_ROBOTS_ACTIVE){
            NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS_ACTIVE + NUMBER_ROBOTS ;
            BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
            Print("Adicionando novos robos: " + NUMBER_ROBOTS_ACTIVE);
         }else{
            Print("Maximo de robôs permitidos ");
         }
      }else  if(profit <  -(BALANCE_ACTIVE * ACTIVE_VOLUME)){
         NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
         //NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS_ACTIVE - NUMBER_ROBOTS > NUMBER_ROBOTS ? NUMBER_ROBOTS_ACTIVE - NUMBER_ROBOTS : NUMBER_ROBOTS;
         BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
         Print("Removendo robos: " + NUMBER_ROBOTS_ACTIVE);
      }
   }else{
      NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
   }
   
   if(BALANCE_ACTIVE / INITIAL_BALANCE >= 10){
      MULTIPLIER_ROBOTS++;
      INITIAL_BALANCE = BALANCE_ACTIVE;
   }
   
   ArrayResize(robots, NUMBER_ROBOTS_ACTIVE + 2);
   for(int i = 0; i < NUMBER_ROBOTS_ACTIVE; i++)  {
      robots[i] = MAGIC_NUMBER + i; 
   }
}

void toNegociate(double spread){
   if( CopyBuffer(handleVol[0], 0, 0, 5, VOL) == 5){
      MqlRates actualCandle = candles[periodAval-1];
      MqlRates lastCandle = candles[periodAval-2];
     if(VOL[0] <= VOL[2] && VOL[1] <= VOL[3] && VOL[2] <= VOL[3]){
         Print("Alerta de possivel negociação executando");
         ORIENTATION orientCandle1 = verifyValidCandle(candles[periodAval-4]);
         ORIENTATION orientCandle2 = verifyValidCandle(candles[periodAval-3]);
         ORIENTATION orientCandle3 = verifyValidCandle(lastCandle);
         ORIENTATION orientLastCandle = verifyValidCandle(actualCandle);
        
         if(orientLastCandle != MEDIUM){
            countCandles = 0;
            ORIENTATION orient = MEDIUM;
           // ORIENTATION orientAverage = verifyOrientationAverage(actualCandle.close);
           double stopLoss = STOP_LOSS;     
           double takeProfit = calcPoints(candles[periodAval-4].open, actualCandle.close);
           if(orientCandle1 == orientCandle2 && orientCandle2 == orientCandle3 && orientCandle3 != orientLastCandle){  
                waitNewCandle = true;
               
              if(orientLastCandle == UP){
                  stopLoss = calcPoints(actualCandle.close, lastCandle.low);
               }
               
               if(orientLastCandle == DOWN){
                  stopLoss = calcPoints(actualCandle.close, lastCandle.high);
               }
               
               ORIENTATION orientCCI = verifyCCI();
               if(IN_FAVOR == ON){
                  if(orientCCI == orientLastCandle){
                     executeOrderByRobots(orientLastCandle, ACTIVE_VOLUME, stopLoss, takeProfit);
                  }
               }else{
                  if(orientLastCandle == UP && orientCCI == DOWN){
                     executeOrderByRobots(DOWN, ACTIVE_VOLUME, stopLoss, takeProfit);
                  }if(orientLastCandle == DOWN && orientCCI == UP){
                     executeOrderByRobots(UP, ACTIVE_VOLUME, stopLoss, takeProfit);
                  }
               }
               
           }
        /*  else{
               //waitNewCandle = true; 
            if(orientLastCandle == UP){
                  stopLoss = calcPoints(actualCandle.close, lastCandle.low);
                 executeOrderByRobots(DOWN, ACTIVE_VOLUME, stopLoss, stopLoss);
                  
               }
               
               if(orientLastCandle == DOWN){
                  stopLoss = calcPoints(actualCandle.close, lastCandle.high);
                  executeOrderByRobots(UP, ACTIVE_VOLUME, stopLoss, stopLoss);
               }
               
                double topo =  lastCandle.high > candles[periodAval-3].high ?  lastCandle.high : candles[periodAval-3].high;
               double fundo =  lastCandle.low > candles[periodAval-3].low ?  lastCandle.low : candles[periodAval-3].low;
               if(orientLastCandle == UP){
                  if(actualCandle.close > topo && candles[periodAval-4].high < candles[periodAval-3].high && candles[periodAval-2].high < candles[periodAval-3].high){
                     stopLoss = calcPoints(actualCandle.close, lastCandle.low);
                     executeOrderByRobots(UP, ACTIVE_VOLUME, stopLoss, takeProfit);
                  }
               }
               
               if(orientLastCandle == DOWN){
                  if(actualCandle.close < fundo && candles[periodAval-4].low > candles[periodAval-3].low && candles[periodAval-2].low > candles[periodAval-3].low){
                     stopLoss = calcPoints(actualCandle.close, lastCandle.high);
                     executeOrderByRobots(DOWN, ACTIVE_VOLUME, stopLoss, takeProfit);
                  }
               }  
           }  */
         }
      }
   }
}

ORIENTATION verifyValidCandle(MqlRates& candle){
   double pointsCandle = calcPoints(candle.close, candle.open);
   double pointsShadow = calcPoints(candle.low, candle.high);
   if(MathAbs(pointsCandle-pointsShadow) < pointsCandle){
      if(verifyIfOpenBiggerThanClose(candle)){
         return DOWN;
      }else if(!verifyIfOpenBiggerThanClose(candle)){
         return UP;
      }
   }

   return MEDIUM;
}

ORIENTATION verifyOrientationAverage(double closePrice){
   if(CopyBuffer(handleaverages[0], 0, 0, periodAval, averages8) == periodAval && 
      CopyBuffer(handleaverages[1], 0, 0, periodAval, averages20) == periodAval &&
      CopyBuffer(handleaverages[2], 0, 0, periodAval, averages80) == periodAval &&  
      CopyBuffer(handleaverages[3], 0, 0, periodAval, averages200) == periodAval){
         if(averages20[periodAval-1] < closePrice && averages80[periodAval-1] < closePrice && averages8[periodAval-1] < closePrice){
            return UP;
         }
         
         if(averages20[periodAval-1] > closePrice&& averages80[periodAval-1] > closePrice && averages8[periodAval-1] > closePrice){
            return DOWN;
         }
      }
   
   return MEDIUM;
}


string verifyPeriod(ORIENTATION orient){
   if(orient == DOWN){
      return "DOWN";
   }
   if(orient == UP){
      return "UP";
   }
   
   return "MEDIUM";
}

void closeAllPositionsByType(ENUM_POSITION_TYPE type, double stop, double takeProfit){
   int pos = PositionsTotal() - 1;
   for(int i = pos; i >= 0; i--)  {
      if(hasPositionOpen(i)){
         ulong ticket = PositionGetTicket(i);
         PositionSelectByTicket(ticket);
         ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
         double profit = PositionGetDouble(POSITION_PROFIT);
         double pointsProfit =  MathAbs(profit / ACTIVE_VOLUME);
         if(verifyMagicNumber(i, magicNumber)){
               closeBuyOrSell(i);
         }
      }
   }
}

void executeOrderByRobots(ORIENTATION orient, double volume, double stop, double take){
  if(countRobots < NUMBER_ROBOTS_ACTIVE){
   if(!hasPositionOpen((int)robots[countRobots])){
      if(countRobots > 1){
        //stop = (stop / countRobots) > STOP_LOSS ? (stop / countRobots) : STOP_LOSS;
       // take =TAKE_PROFIT;
      }
      
      if(bestOrientation == MEDIUM || bestOrientation == orient){
         toBuyOrToSell(orient, volume, (stop), (take), robots[countRobots]);
         countRobots++;
      }
   }
  }else{
      countRobots = PositionsTotal();
  }
}

void moveAllPositions(double spread){
   int pos = PositionsTotal() - 1;
   double  average[];
   for(int i = pos; i >= 0; i--)  {
      if(hasPositionOpen(i)){
         if(ACTIVE_MOVE_STOP == ON){
            activeStopMovelPerPoints(PONTUATION_MOVE_STOP+spread, i);
         }
         if(ACTIVE_MOVE_TAKE == ON){
            moveTakeProfit(i);
         }
      }
   }
   
   decideToCreateOrDeleteRobots();
   if(pos <= 0){
      bestOrientation = MEDIUM;
   }
}

ORIENTATION verifyForceIndex(){
   double forceIArray[], forceValue[5], fiMax = 0, fiMin = 0, fMedia = 0;
   //ArraySetAsSeries(forceIArray, true);   
   
   if(CopyBuffer(handleFI,0,0,handleFI,forceIArray) == handleFI){
      //fiMax = forceIArray[ArrayMaximum(forceIArray,0,handleFI/2)];
      //fiMin = forceIArray[ArrayMinimum(forceIArray,0,handleFI/2)];
      //points = calcPoints(fiMax, 0);
      //points = calcPoints(fiMin, 0);
      if(handleFI > 5){
         forceValue[0] = NormalizeDouble(forceIArray[handleFI-1], _Digits);
         forceValue[1] = NormalizeDouble(forceIArray[handleFI-2], _Digits);
         forceValue[2] = NormalizeDouble(forceIArray[handleFI-3], _Digits);
         forceValue[3] = NormalizeDouble(forceIArray[handleFI-4], _Digits);
         forceValue[4] = NormalizeDouble(forceIArray[handleFI-5], _Digits);
         fMedia =  forceValue[0] + forceValue[1] + forceValue[2] + forceValue[3] + forceValue[4];
         
         if(fMedia >= 1000 ){
            return UP;
         }else if(fMedia <= -1000 ){
            return DOWN;
         }
      }
   }
   
   return MEDIUM;
}


ORIENTATION verifyRSI(double rsi, double rsi0){
   if(rsi >= 70 && rsi0 < 70){
      return DOWN;
   }
   if(rsi <= 30 && rsi0 > 30){
      return UP;
   }

   return MEDIUM;
}

ORIENTATION verifyCCI(){
   double CCI[];
   if(CopyBuffer(handleICCI,0,0,periodAval,CCI) == periodAval){
      if(CCI[periodAval-1] > 0 && CCI[periodAval-1] < 99){
         return UP;
      }
      if(CCI[periodAval-1] < 0 && CCI[periodAval-1] > -99){
         return DOWN;
      }
      if(CCI[periodAval-1] >= 100){
         return DOWN;
      }
      if(CCI[periodAval-1] <= -100){
         return UP;
      }
   }

   return MEDIUM;
}

void  decideToCreateOrDeleteRobots(){
   int countBuy = 0, countSell = 0;
   int pos = PositionsTotal() - 1;
   double  average[];
   for(int position = pos; position >= 0; position--)  {
      if(hasPositionOpen(position)){
         ulong ticket = PositionGetTicket(position);
         PositionSelectByTicket(ticket);
         double newTpPrice = 0, newSlPrice = 0;
         ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
         if(verifyMagicNumber(position, magicNumber)){
            double tpPrice = PositionGetDouble(POSITION_TP);
            double slPrice = PositionGetDouble(POSITION_SL);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double pointsProfit =  MathAbs(profit / ACTIVE_VOLUME);
            double pointsTake = calcPoints(entryPrice, tpPrice);
            double pointsSL = calcPoints(entryPrice, slPrice);
            newTpPrice = tpPrice;
            
            if(profit > 0){
              if(pointsProfit >= pointsTake * 0.2 &&  pointsProfit <= pointsTake * 0.6){
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                  countBuy++;
                }
                else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                  countSell++;
               }
             }
           }
             else if(profit < 0){
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                  countBuy--;
                }
                else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                  countSell--;
               }
              // if(pointsProfit >= pointsSL * 0.3){
                //  closeBuyOrSell(position);
              // }
            }/* */
         }
      }
   }
            
   double profit2 =  AccountInfoDouble(ACCOUNT_PROFIT);
   if(countBuy >= 0 && countSell >= 0 && profit2 > 0){
      ORIENTATION orientAverages = verifyOrientationAverage(candles[periodAval-1].close);
      if(countBuy > countSell){
         if(orientAverages != DOWN ){
            bestOrientation = BUY;
            executeOrderByRobots(UP, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT);
         }
      }
      else if(countBuy < countSell){
         if(orientAverages != UP ){
            bestOrientation = DOWN;
            executeOrderByRobots(DOWN, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT);
         }
      }
   }
}

void  moveTakeProfit( int position = 0){
   double newTpPrice = 0, newSlPrice = 0;
   if(hasPositionOpen(position)){ 
      ulong ticket = PositionGetTicket(position);
      
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
            double tpPrice = PositionGetDouble(POSITION_TP);
            double slPrice = PositionGetDouble(POSITION_SL);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double pointsProfit =  MathAbs(profit / ACTIVE_VOLUME);
            double pointsTake = calcPoints(entryPrice, tpPrice);
            double pointsSL = calcPoints(entryPrice, slPrice);
            newTpPrice = tpPrice;
            
            if(profit > 0){
              newSlPrice = slPrice;
              if(pointsProfit >= pointsTake * 0.60 ){
                  double mov =  NormalizeDouble((pointsTake * PONTUATION_MOVE_STOP / 100 * _Point), _Digits);
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                     newTpPrice = (tpPrice + mov);
                     newSlPrice = (tpPrice + mov);
                   //  slPrice = slPrice > entryPrice ? slPrice : entryPrice;
                  }
                  else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                     newTpPrice = (tpPrice - mov);
                     newSlPrice = (tpPrice - mov);
                    // slPrice = slPrice < entryPrice ? slPrice : entryPrice;
                  }
                  
                  tradeLib.PositionModify(ticket, slPrice, newTpPrice);
                  if(verifyResultTrade()){
                     Print("Take movido");
                  }
              }
           }
       }
   }
}

void  activeStopMovelPerPoints(double points, int position = 0){
   double newSlPrice = 0;
   if(hasPositionOpen(position)){ 
      PositionSelectByTicket(PositionGetTicket(position));
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         double tpPrice = PositionGetDouble(POSITION_TP);
         double slPrice = PositionGetDouble(POSITION_SL);
         double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double profit = PositionGetDouble(POSITION_PROFIT);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double entryPoints = 0, pointsInversion =  MathAbs(profit / ACTIVE_VOLUME);
         double pointsTake = calcPoints(entryPrice, tpPrice);
         bool modify = false, inversion = false;
         ORIENTATION orient = MEDIUM;
         newSlPrice = slPrice;
         points = points < pointsTake ? points : pointsTake;
         
         double mov = (points * PERCENT_MOVE / 100 * _Point);
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
            //tpPrice = NormalizeDouble((tpPrice + (points * _Point)), _Digits);
            if(slPrice >= entryPrice ){
               entryPoints = calcPoints(slPrice, currentPrice);
               newSlPrice = NormalizeDouble((slPrice + mov), _Digits);
               modify = true;
            }else if(currentPrice > entryPrice+ mov){
               entryPoints = calcPoints(entryPrice, currentPrice);
               newSlPrice = entryPrice;
               modify = true;
            }
         }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
          //  tpPrice = NormalizeDouble((tpPrice - (points * _Point)), _Digits);
            if(slPrice <= entryPrice ){
               entryPoints = calcPoints(slPrice, currentPrice);
               newSlPrice = NormalizeDouble((slPrice - mov), _Digits);
               modify = true;
            }else if(currentPrice < entryPrice- mov){
               entryPoints = calcPoints(entryPrice, currentPrice);
               newSlPrice = entryPrice;
               modify = true;
            }
         }
            
         if(modify == true && entryPoints != 0 && entryPoints >= points){
            tradeLib.PositionModify(PositionGetTicket(position), newSlPrice, tpPrice);
            if(verifyResultTrade()){
               Print("Stop movido");
            }
         }
      }
   }
}
      

BordersOperation normalizeTakeProfitAndStopLoss(double stopLoss, double takeProfit){
   BordersOperation borders;
   // modificação para o indice dolar DOLAR_INDEX
   if(stopLoss != 0 || takeProfit != 0){
      if(_Digits == 3){
         borders.min = (stopLoss * 1000);
         borders.max = (takeProfit * 1000);  
      }else{
         borders.min = NormalizeDouble((stopLoss * _Point), _Digits);
         borders.max = NormalizeDouble((takeProfit * _Point), _Digits); 
      }
   }
   
   return borders;
}

void toBuy(double volume, double stopLoss, double takeProfit){
   SymbolInfoTick(_Symbol, tick);
   double stopLossNormalized = NormalizeDouble((tick.ask - stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.ask + takeProfit), _Digits);
   tradeLib.Buy(volume, _Symbol, NormalizeDouble(tick.ask,_Digits), stopLossNormalized, takeProfitNormalized); 
}

void toSell(double volume, double stopLoss, double takeProfit){
   SymbolInfoTick(_Symbol, tick);
   double stopLossNormalized = NormalizeDouble((tick.bid + stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.bid - takeProfit), _Digits);
   tradeLib.Sell(volume, _Symbol, NormalizeDouble(tick.bid,_Digits), stopLossNormalized, takeProfitNormalized);   
}

bool realizeDeals(TYPE_NEGOCIATION typeDeals, double volume, double stopLoss, double takeProfit, ulong magicNumber){
   if(typeDeals != NONE){
   
      BordersOperation borders = normalizeTakeProfitAndStopLoss(stopLoss, takeProfit); 
    //  if(hasPositionOpen() == false) {
         if(typeDeals == BUY){ 
            toBuy(volume, borders.min, borders.max);
         }
         else if(typeDeals == SELL){
            toSell(volume, borders.min, borders.max);
         }
         
         if(verifyResultTrade()){
            tradeLib.SetExpertMagicNumber(magicNumber);
            Print("MAGIC NUMBER: " + IntegerToString(magicNumber));
            return true;
         }
      // }
    }
    
    return false;
 }

void closeBuyOrSell(int position){
   if(hasPositionOpen(position)){
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         tradeLib.PositionClose(ticket);
         if(verifyResultTrade()){
            Print("Negociação concluída.");
         }
      }
   }
}

bool verifyMagicNumber(int position = 0, ulong magicNumberRobot = 0){
   if(hasPositionOpen(position)){
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      
     // if(magicNumberRobot == 0){
     //    magicNumberRobot = MAGIC_NUMBER;
     // }
      
      if(USE_MAGIC_NUMBER == OFF){
         return true;
      }else if(magicNumber == magicNumberRobot){
         return true;
      }
   }
   
   return false;
   
}

bool toBuyOrToSell(ORIENTATION orient, double volume, double stopLoss, double takeProfit, ulong magicNumber){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   return realizeDeals(typeDeal, volume, stopLoss, takeProfit, magicNumber);
   //getHistory();
}

bool hasPositionOpen(int position ){
    string symbol = PositionGetSymbol(position);
    if(PositionSelect(symbol) == true) {
      return true;       
    }
    
    return false;
}

bool verifyResultTrade(){
   if(tradeLib.ResultRetcode() == TRADE_RETCODE_PLACED || tradeLib.ResultRetcode() == TRADE_RETCODE_DONE){
      printf("Ordem de %s executada com sucesso.");
      return true;
   }else{
      Print("Erro de execução de ordem ", GetLastError());
      ResetLastError();
      return false;
   }
}

BordersOperation drawBorders(double precoAtual, double pontuationEstimateHigh = 0, double pontuationEstimateLow = 0){
   BordersOperation borders;
   /*
   int numCandles = 2;
   int copiedPrice = CopyRates(_Symbol,_Period,0,numCandles,candles);
   if(copiedPrice == numCandles){
      for(int i = 0; i < numCandles; i++){
         pontuationEstimateHigh += (candles[i].high) ;
         pontuationEstimateLow += (candles[i].low);
      }
      pontuationEstimateHigh = pontuationEstimateHigh /numCandles;
      pontuationEstimateLow = pontuationEstimateLow /numCandles;
      borders.max = MathAbs(_Point * pontuationEstimateHigh + precoAtual);
      borders.min = MathAbs(_Point * pontuationEstimateLow - precoAtual);
   }*/
   
   borders.max = MathAbs(_Point * pontuationEstimateHigh + precoAtual);
   borders.min = MathAbs(_Point * pontuationEstimateLow - precoAtual);
  
   drawHorizontalLine(borders.max, 0, "BorderMax", clrYellow);
   drawHorizontalLine(borders.min, 0, "BorderMin", clrYellow);
   //Print("Atualização de Bordas");
   
   return borders;
}

bool hasNewCandle(){
   static datetime lastTime = 0;
   
   datetime lastBarTime = (datetime)SeriesInfoInteger(Symbol(),PERIOD_CURRENT,SERIES_LASTBAR_DATE);
   
   //primeira chamada da funcao
   if(lastTime == 0){
      lastTime = lastBarTime;
      return false;
   }
   
   if(lastTime != lastBarTime){
      lastTime = lastBarTime;
      return true;
   }
   
   return false;
}

void drawHorizontalLine(double price, datetime time, string nameLine, color indColor){
   ObjectCreate(ChartID(),nameLine,OBJ_HLINE,0,time,price);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
   ObjectMove(ChartID(),nameLine,0,time,price);
}

void drawArrow(datetime time, string nameLine, double price, ORIENTATION orientation, color indColor){
   if(orientation == UP){
      ObjectCreate(ChartID(),nameLine,OBJ_ARROW_UP,0,time,price);
      ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   }else{
      ObjectCreate(ChartID(),nameLine,OBJ_ARROW_DOWN,0,time,price);
      ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   }
}

void drawVerticalLine(datetime time, string nameLine, color indColor){
   ObjectCreate(ChartID(),nameLine,OBJ_VLINE,0,time,0);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
}

void createButton(string nameLine, int xx, int yy, int largura, int altura, int canto, int tamanho, string fonte, string text, long corTexto, long corFundo, long corBorda, bool oculto){
   ObjectCreate(ChartID(),nameLine,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,nameLine,OBJPROP_XDISTANCE,xx);
   ObjectSetInteger(0,nameLine,OBJPROP_YDISTANCE, yy);
   ObjectSetInteger(0,nameLine,OBJPROP_XSIZE, largura);
   ObjectSetInteger(0,nameLine,OBJPROP_YSIZE, altura);
   ObjectSetInteger(0,nameLine,OBJPROP_CORNER, canto);
   ObjectSetInteger(0,nameLine,OBJPROP_FONTSIZE, tamanho);
   ObjectSetString(0,nameLine,OBJPROP_FONT, fonte);
   ObjectSetString(0,nameLine,OBJPROP_TEXT, text);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR, corTexto);
   ObjectSetInteger(0,nameLine,OBJPROP_BGCOLOR, corFundo);
   ObjectSetInteger(0,nameLine,OBJPROP_BORDER_COLOR, corBorda);
}


bool timeToProtection(string startTime, string endTime){
   datetime now = TimeCurrent();
   datetime start = StringToTime(startTime);
   datetime end = StringToTime(endTime);
   
   if(startTime == "00:00" && endTime == "00:00"){
      return false;
   }else{
      if(now > start && now < end){
         return true;
      }
   }
   
   return false;
}

bool verifyIfOpenBiggerThanClose(MqlRates& candle){
   return candle.open > candle.close;
}

ORIENTATION getOrientationPerCandles(MqlRates& prev, MqlRates& actual){
   if(actual.open > prev.open){
      return UP;
   }else if(actual.open < prev.open){
      return DOWN;
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

bool isNewDay(datetime startedDatetimeRobot){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(startedDatetimeRobot, structDate);
   
   if((structActual.day_of_year - structDate.day_of_year) > 0){
      return true;
   }else{
      return false;
   }
}

int getActualDay(datetime startedDatetimeRobot){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(startedDatetimeRobot, structDate);
   return (structActual.day_of_year - structDate.day_of_year);
}

double calcPoints(double val1, double val2, bool absValue = true){
   if(absValue){
      return MathAbs(val1 - val2) / _Point;
   }else{
      return (val1 - val2) / _Point;
   }
}

void instanciateBorder(BordersOperation& borders){
     borders.max = 0;
     borders.min = 0;
     borders.central = 0;
     borders.instantiated = false;
     borders.orientation = MEDIUM;
}
