#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"



#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

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

input double ACCEPTABLE_VOLUME = 0;
input POWER  ACTIVE_MOVE_TAKE = ON;
input POWER  ACTIVE_MOVE_STOP = ON;
input double PERCENT_MOVE = 70;
input double PONTUATION_MOVE_STOP = 200;
input double PONTUATION_ESTIMATE = 500;
input double ACTIVE_VOLUME = 0.01;
input string CLOSING_TIME = "23:00";
input ulong MAGIC_NUMBER = 3232131231231231;
input POWER USE_MAGIC_NUMBER = ON;
input int NUMBER_ROBOTS = 25;
input double TAKE_PROFIT = 2000;
input double STOP_LOSS = 1000;
input int COUNT_TICKS = 150;

MqlRates candles[];
datetime actualDay = 0;
bool negociationActive = false;
MqlTick tick;                // variável para armazenar ticks 

ORIENTATION orientMacro = MEDIUM;
int periodAval = 4, countRobots = 0, countTicks = 0;
bool waitNewCandle = false;
ulong robots[];

MqlRates candleMacro;
double averages[], averages8[], averages20[], averages80[], averages200[], MACD[], MACD5[], CCI[], FI[], VOL[], pointsMacro = 0;
double upperBand[], middleBand[], lowerBand[], upperBand5[], middleBand5[], lowerBand5[], RVI1[], RVI2[], RSI[];
int handleaverages[4], handleBand[2] ,handleCCI[2], handleVol[2], handleMACD[2], handleIRVI, handleFI, handleIRSI;

int OnInit(){
      handleaverages[3] = iMA(_Symbol,PERIOD_D1, 10, 0, MODE_SMA, PRICE_CLOSE);
      handleVol[0] = iVolumes(_Symbol,PERIOD_D1,VOLUME_TICK);
      
      handleIRVI = iRVI(_Symbol,PERIOD_D1,3);
      handleCCI[0] = iCCI(_Symbol,PERIOD_D1,14,PRICE_TYPICAL);
      handleFI = iForce(_Symbol,PERIOD_D1,14,MODE_SMA,VOLUME_TICK);
      handleIRSI = iRSI(_Symbol,PERIOD_D1,14,PRICE_CLOSE);
      
      ArrayResize(robots, NUMBER_ROBOTS + 2);
      for(int i = 0; i < NUMBER_ROBOTS; i++)  {
         robots[i] = MAGIC_NUMBER + i; 
      }
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
      if(hasNewCandle()){
         waitNewCandle = false;
      }else{
         double spread = candles[periodAval-1].spread;
         if(!waitNewCandle){
            toNegociate(spread);
         }
         
         if(countTicks > COUNT_TICKS){
            moveAllPositions(spread);
            countTicks = 0;
         }
         countTicks++;
      }
   }
}

void toNegociate(double spread){
   if( CopyBuffer(handleVol[0], 0, 0, periodAval, VOL) == periodAval){
      datetime now = TimeCurrent();
      datetime closingTime = StringToTime(CLOSING_TIME);
      if(now > closingTime){
         MqlRates actualCandle = candles[periodAval-1];
         MqlRates lastCandle = candles[periodAval-2];
         double points = calcPoints(lastCandle.high, lastCandle.low);
         double pointsBody = calcPoints(lastCandle.open, lastCandle.close);
         double takeProfit = TAKE_PROFIT > 0 ? TAKE_PROFIT : 2 * points;
         double stopLoss = STOP_LOSS > 0 ? STOP_LOSS : points;
         if(points >= PONTUATION_ESTIMATE && VOL[periodAval-1] >= ACCEPTABLE_VOLUME){
            ORIENTATION orient = MEDIUM;
           // ORIENTATION orientAverage = verifyOrientationAverage(actualCandle.close);
            double middlePoint = (lastCandle.high + lastCandle.low) / 2;
            if(middlePoint > actualCandle.high ){ 
               orient = DOWN;
               //closeAllPositionsByType(POSITION_TYPE_BUY, stopLoss, takeProfit);
            }else if(middlePoint < actualCandle.low){
               orient = UP;
               //closeAllPositionsByType(POSITION_TYPE_SELL, stopLoss, takeProfit);
            }
            
            if(orient != MEDIUM){    
               waitNewCandle = true;
               executeOrderByRobots(orient, ACTIVE_VOLUME, stopLoss, takeProfit);
            }
         }
      }
   }
}

ORIENTATION verifyOrientationAverage(double closePrice){
   if(CopyBuffer(handleaverages[0], 0, 0, periodAval, averages8) == periodAval && 
      CopyBuffer(handleaverages[1], 0, 0, periodAval, averages80) == periodAval &&
      CopyBuffer(handleaverages[2], 0, 0, periodAval, averages20) == periodAval &&  
      CopyBuffer(handleaverages[3], 0, 0, periodAval, averages200) == periodAval){
         if(averages200[periodAval-1] < closePrice){
            return UP;
         }
         
         if(averages200[periodAval-1] > closePrice){
            return DOWN;
         }
      }
   
   return MEDIUM;
}


bool hasTopOrBottom(int period, POSITION_GRAPHIC position, double currentPrice){
   MqlRates candlesAux[];
   bool hasPosition = false;
   int copiedPrice = CopyRates(_Symbol,_Period,0,period,candlesAux);
   if(copiedPrice == period){
      if(period > 3) {
         for(int i = 0; i < period-1; i++){
            if(i-4 >= 0){
               MqlRates last = candlesAux[i-2];
               MqlRates secondLast = candlesAux[i-3];
               MqlRates first = candlesAux[i-4];
               if(verifyPositionGraphic(last,secondLast, first) == position){
                  if(position == TOP){
                     if((last.high >= currentPrice || secondLast.high >= currentPrice || first.high >= currentPrice)){
                        hasPosition = true;
                        break;
                     }
                  }else if(position == BOTTOM){
                     if((last.low <= currentPrice || secondLast.low <= currentPrice || first.low <= currentPrice)){
                        hasPosition = true;
                        break;
                     }
                  }
               }
            }
         }
      }
   }
   
   return hasPosition;
}

POSITION_GRAPHIC verifyPositionGraphic(MqlRates& last, MqlRates& secondLast, MqlRates& first){
   double minPointsLeft, minPointsRight, points = 10;
   
   minPointsLeft = calcPoints(first.low, secondLast.low);
   minPointsRight = calcPoints(last.low, secondLast.low);
   if(minPointsLeft > points && minPointsRight > points){
      if(first.low > secondLast.low && last.low > secondLast.low){
         return BOTTOM;
      }
   }
   
   minPointsLeft = calcPoints(first.high, secondLast.high);
   minPointsRight = calcPoints(last.high, secondLast.high);
   if(minPointsLeft > points && minPointsRight > points){
      if(first.high < secondLast.high && last.high < secondLast.high){
         return TOP;
      }
   }
   
   return CENTER;
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
            if(PositionGetInteger(POSITION_TYPE) == type && profit < 0 && pointsProfit >= stop * 0.7 ){
               closeBuyOrSell(i);
               /*if(type == POSITION_TYPE_BUY){
                  executeOrderByRobots(DOWN, ACTIVE_VOLUME, stop, takeProfit);
               }
               else if(type == POSITION_TYPE_SELL){
                  executeOrderByRobots(UP, ACTIVE_VOLUME, stop, takeProfit);
               }*/
            }
         }
      }
   }
}

void executeOrderByRobots(ORIENTATION orient, double volume, double stop, double take){
  if(countRobots < NUMBER_ROBOTS){
       if(CopyBuffer(handleCCI[0],0,0,periodAval,CCI) == periodAval && 
         CopyBuffer(handleIRVI,0,0,periodAval,RVI1) == periodAval &&    
         CopyBuffer(handleIRVI,1,0,periodAval,RVI2) == periodAval &&
         CopyBuffer(handleIRSI,0,0,periodAval,RSI) == periodAval){
         ORIENTATION orientCCI, orientRVI, orientFI, orientRSI;
         
        //  || (orientCCI == orientRVI && orientCCI != orient)
        
         orientFI = verifyForceIndex();
         orientCCI = verifyCCI(CCI[periodAval-1]);
         orientRVI = verifyRVI(RVI1[periodAval-1], RVI2[periodAval-1]);
         orientRSI = verifyRSI(RSI[periodAval-1], RSI[0]);
         if(orient != orientRVI && orient != orientFI && orient != orientCCI && orient != orientRSI){
            if(!hasPositionOpen((int)robots[countRobots])){
               if(orient == UP){
                  toBuyOrToSell(DOWN, volume, stop, take, robots[countRobots]);
                  countRobots++;
               }else if(orient == DOWN){
                  toBuyOrToSell(UP, volume, stop, take, robots[countRobots]);
                  countRobots++;
               }
            }
         }else{
            if(!hasPositionOpen((int)robots[countRobots])){
               toBuyOrToSell(orient, volume, stop, take, robots[countRobots]);
               countRobots++;
            }
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
            moveTakeProfit( i);
         }
      }
   }
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

ORIENTATION verifyRVI(double rvi1, double rvi2){
   if(rvi1 < rvi2 && rvi2 < 0){
      //Print("Trend DOWN");
      return DOWN;
   }
   if(rvi1 > rvi2 && rvi1 > 0){
      //Print("Trend UP");
      return UP;
   }
   
   if(rvi1 < rvi2 && rvi1 > 0){
      //Print("CORRECTION DOWN");
      return DOWN;
   }
   if(rvi1 > rvi2 && rvi2 < 0){
      //Print("CORRECTION UP");
      return UP;
   }

   return MEDIUM;
}

ORIENTATION verifyForceIndex(){
   double forceIArray[], forceValue, fiMax = 0, fiMin = 0;
   //ArraySetAsSeries(forceIArray, true);   
   
   if(CopyBuffer(handleFI,0,0,handleFI,forceIArray) == handleFI){
      forceValue = NormalizeDouble(forceIArray[handleFI-1], _Digits);
      //fiMax = forceIArray[ArrayMaximum(forceIArray,0,handleFI/2)];
      //fiMin = forceIArray[ArrayMinimum(forceIArray,0,handleFI/2)];
      //points = calcPoints(fiMax, 0);
      //points = calcPoints(fiMin, 0);
      if(forceValue >= 0.05 ){
         return DOWN;
      }else if(forceValue <= -0.05 ){
         return UP;
      }
   }
   
   return MEDIUM;
}

ORIENTATION verifyCCI(double valCCI){
   if(valCCI >= 100){
      return DOWN;
   }
   if(valCCI <= -100){
      return UP;
   }

   return MEDIUM;
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
            newTpPrice = tpPrice;
            
            if(profit > 0){
               if(pointsProfit >= pointsTake * 0.2 && pointsProfit <= pointsTake * 0.5){
               // && !hasTopOrBottom(12, TOP, currentPrice)
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                     executeOrderByRobots(UP, ACTIVE_VOLUME, STOP_LOSS, pointsTake * 0.4);
                  }
                  else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                     executeOrderByRobots(DOWN, ACTIVE_VOLUME, STOP_LOSS, pointsTake * 0.4);
                  }
              }
           
              if(pointsProfit >= pointsTake * 0.95 ){
                  newSlPrice = NormalizeDouble(pointsTake * PERCENT_MOVE / 100, _Digits);
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                     newTpPrice = NormalizeDouble(tpPrice + (pointsTake * _Point), _Digits);
                  }
                  else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                     newTpPrice = NormalizeDouble(tpPrice - (pointsTake * _Point), _Digits);
                  }
                  
                  tradeLib.PositionModify(ticket, newSlPrice, newTpPrice);
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
         bool modify = false, inversion = false;
         ORIENTATION orient = MEDIUM;
         newSlPrice = slPrice;
         
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
            //tpPrice = NormalizeDouble((tpPrice + (points * _Point)), _Digits);
            if(slPrice >= entryPrice ){
               entryPoints = calcPoints(slPrice, currentPrice);
               newSlPrice = NormalizeDouble((slPrice + (points * PERCENT_MOVE / 100 * _Point)), _Digits);
               modify = true;
            }else if(currentPrice > entryPrice+ (points * PERCENT_MOVE / 100 * _Point)){
               entryPoints = calcPoints(entryPrice, currentPrice);
               newSlPrice = entryPrice;
               modify = true;
            }
         }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
          //  tpPrice = NormalizeDouble((tpPrice - (points * _Point)), _Digits);
            if(slPrice <= entryPrice ){
               entryPoints = calcPoints(slPrice, currentPrice);
               newSlPrice = NormalizeDouble((slPrice - (points * PERCENT_MOVE / 100 * _Point)), _Digits);
               modify = true;
            }else if(currentPrice < entryPrice- (points * PERCENT_MOVE / 100 * _Point)){
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
