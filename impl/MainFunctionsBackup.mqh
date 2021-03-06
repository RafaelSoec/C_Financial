//+------------------------------------------------------------------+
//|                                                MainFunctions.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <Trade\Trade.mqh>
//#include <Canvas\Canvas.mqh>


//CCanvas canvasLib;


CTrade tradeLib;

enum AVERAGE_PONTUATION{
   AVERAGE_0,
   AVERAGE_5,
   AVERAGE_10,
   AVERAGE_15,
   AVERAGE_20,
   AVERAGE_25,
   AVERAGE_30,
};

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
};

struct PeriodProtectionTime {
   string dealsLimitProtection;
   string endProtection;
   string startProtection;
   bool instantiated;
};

input int WAIT_CANDLES = 5;
input int PERIOD = 5;
input POWER AGAINST_CURRENT = ON;
input int PONTUATION_ESTIMATE = 100;
input double ACTIVE_VOLUME = 1.0;
input double TAKE_PROFIT = 250;
input double STOP_LOSS = 60;
input double LOSS_PER_DAY = 0;
input double PROFIT_PER_DAY = 0;
input double START_PRICE_CHANNEL = 0;
input string SCHEDULE_START_DEALS = "07:00";
input string SCHEDULE_END_DEALS = "23:00";
input string SCHEDULE_START_PROTECTION = "12:00";
input string SCHEDULE_END_PROTECTION = "13:00";

MqlRates candles[];
datetime actualDay = 0;
bool negociationActive = false;
MqlTick tick;                // variável para armazenar ticks 

void startRobots(){
  printf("Start Robots in " +  _Symbol);
  Print("Negociações Abertas para o dia: ", TimeToString(TimeCurrent(), TIME_DATE));
}

void finishRobots(){
  printf("Finish Robots in " +  _Symbol);
}

ResultOperation getResultOperation(double result){
   ResultOperation resultOperation;
   resultOperation.total = 0;
   resultOperation.losses = 0;
   resultOperation.profits = 0;
   resultOperation.liquidResult = 0;
   resultOperation.profitFactor = 0;
   
   resultOperation.total += result; 
   
   if(result > 0){
      resultOperation.profits += result;
   }
   
   if(result < 0){
      resultOperation.losses += (-result);
   }
   
   resultOperation.liquidResult = resultOperation.profits - resultOperation.losses;
   //Definir fator de lucro
   if(resultOperation.losses > 0){
      resultOperation.profitFactor = resultOperation.profits / resultOperation.losses;
   }else{
      resultOperation.profitFactor = -1;
   }
   
   return resultOperation;
}

ResultOperation getHistory(int countDays){
   ResultOperation resultOperation, resultOp;
   double result = 0;
   
   HistorySelect(0, TimeCurrent());
   ulong trades = HistoryDealsTotal();
   //Print("Total de negociações: ", trades);
   //Print("Lucro Atual: R$ ", resultOperation.liquidResult);
   
   for(uint i = 1; i <= trades; i++)  {
      ulong ticket = HistoryDealGetTicket(i);
      result = HistoryDealGetDouble(ticket,DEAL_PROFIT);    
      resultOp = getResultOperation(result);
      resultOperation.total += resultOp.total;
      resultOperation.losses += resultOp.losses;
      resultOperation.profits += resultOp.profits;
      resultOperation.liquidResult += resultOp.liquidResult;
      resultOperation.profitFactor += resultOp.profitFactor;  
   }
   
   Comment("Trades: " + IntegerToString(trades), 
   " Profits: " + DoubleToString(resultOperation.profits, 2), 
   " Losses: " + DoubleToString(resultOperation.losses, 2), 
   " Profit Factor: " + DoubleToString(resultOperation.profitFactor, 2), 
   " Liquid Result: " + DoubleToString(resultOperation.liquidResult, 2),
   " Number of days: " + IntegerToString(countDays));
   
   return resultOperation;
}

BordersOperation calculateAveragePontuation(AVERAGE_PONTUATION averageSelected){
   BordersOperation averagePontuation;
   averagePontuation.max = 0;
   averagePontuation.min = 0;
   int sizeAverages = 0;
   
   if(averageSelected == AVERAGE_10){
      sizeAverages = 10;
   }else if(averageSelected == AVERAGE_5){
      sizeAverages = 5;
   }else if(averageSelected == AVERAGE_15){
      sizeAverages = 15;
   }else if(averageSelected == AVERAGE_20){
      sizeAverages = 20;
   }else if(averageSelected == AVERAGE_25){
      sizeAverages = 25;
   }else if(averageSelected == AVERAGE_30){
      sizeAverages = 30;
   }

   if(sizeAverages != 0){
      MqlRates averages[];
      ArraySetAsSeries(averages, true);
      int copied = CopyRates(_Symbol,_Period,0,sizeAverages, averages);
      if(copied){
         for(int i = 0; i < sizeAverages; i++){
            averagePontuation.max += averages[i].high;
            averagePontuation.min += averages[i].low;
         }
         averagePontuation.max = averagePontuation.max / sizeAverages;
         averagePontuation.min = averagePontuation.min / sizeAverages;
      }
   }
   
   return averagePontuation;
}

int verifyDayTrade(datetime timeStarted, int countDays, double liquidResult){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   //if(countDays == 1 && timeStarted == 0){
   //   timeStarted = TimeCurrent();
   //}
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(timeStarted, structDate);
   if(structDate.day_of_year != structActual.day_of_year){
      countDays++; 
      Print("Ganho do dia -> R$", DoubleToString(liquidResult, 2));
      Print("Negociações Encerradas para o dia: ", TimeToString(timeStarted, TIME_DATE));
      Print("Negociações Abertas para o dia: ", TimeToString(actualTime, TIME_DATE));
      timeStarted = actualTime;
   }
   
   return countDays;
}


double activeStopMovel(double prevPrice, MqlRates& candle){
   if(hasPositionOpen()){
      double tpPrice = PositionGetDouble(POSITION_TP);
      double slPrice = PositionGetDouble(POSITION_SL);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
       /*  if(((entryPrice - actualPrice) / _Point) > STOP_LOSS){
            closeBuyOrSell(0);
         }*/
         
          if(prevPrice == 0){
            prevPrice = entryPrice;
          }
         
          if(prevPrice < candle.close && entryPrice < candle.close){
            double newSlPrice = MathAbs(candle.close - MathAbs((prevPrice-slPrice)));
            prevPrice = candle.close;
            //double newTpPrice = MathAbs(prevPrice + MathAbs((entryPrice-tpPrice)));  
            tradeLib.PositionModify(_Symbol, newSlPrice, tpPrice);
            if(verifyResultTrade()){
               Print("Stop movido");
            }
         }
      }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
       /*  if(((actualPrice - entryPrice) / _Point) > STOP_LOSS){
            closeBuyOrSell(0);
         }*/
         if(prevPrice == 0){
           prevPrice = entryPrice;
         }
          
         if(prevPrice > candle.close && entryPrice > candle.close ){
            double newSlPrice = MathAbs(candle.close + MathAbs((prevPrice-slPrice))); 
            prevPrice = candle.close;
             //double newTpPrice = MathAbs(prevPrice - MathAbs((entryPrice-tpPrice)));  
            tradeLib.PositionModify(_Symbol, newSlPrice, tpPrice);
            if(verifyResultTrade()){
               Print("Stop movido");
            }
         }
      }
   }
   
   return prevPrice;
}
        

/*/
double activeStopMovel(MqlRates& prevCandle, MqlRates& decisionCandle, MqlRates& actualCandle, double entryPrice){
   if(hasPositionOpen() == true){
      for(int i = PositionsTotal()-1; i >= 0; i--){
         string symbol = PositionGetSymbol(i);
         if(_Symbol == symbol){
            double tpPrice = PositionGetDouble(POSITION_TP);
            double slPrice = PositionGetDouble(POSITION_SL);
            double entryDeal = PositionGetDouble(POSITION_PRICE_OPEN);
            ulong ticket = PositionGetTicket(i);
            
            BordersOperation bords = normalizeTakeProfitAndStopLoss(STOP_LOSS, TAKE_PROFIT);
           
            if(entryPrice == 0){
               entryPrice = entryDeal;
            } 
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
               if(decisionCandle.open < decisionCandle.close ){
                  if(entryDeal > decisionCandle.low){
                     entryPrice = entryDeal;
                  }else{
                     entryPrice = decisionCandle.low;
                  }
                  
                  if(entryPrice < slPrice){
                     entryPrice = slPrice;
                  }
                  tradeLib.PositionModify(ticket,entryPrice,tpPrice);
               }
            }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
               if(decisionCandle.open > decisionCandle.close ){
                  if(entryDeal < decisionCandle.high){
                     entryPrice = entryDeal;
                  }else{
                     entryPrice = decisionCandle.high;
                  }
                  
                  if(entryPrice > slPrice){
                     entryPrice = slPrice;
                  }
                  
               }
            } 
            
            if(entryPrice > 0) {
               tradeLib.PositionModify(ticket,entryPrice,tpPrice);
               if(verifyResultTrade() == false){
               }
            }
         }
      
      }
      
      
   }
   
   return entryPrice;
}*/

double activeOpenEnd(MqlRates& actualCandle, double entryPrice){
   if(hasPositionOpen() == true){
      for(int i = PositionsTotal()-1; i >= 0; i--){
         string symbol = PositionGetSymbol(i);
         if(_Symbol == symbol){
            double tpPrice = PositionGetDouble(POSITION_TP);
            double slPrice = PositionGetDouble(POSITION_SL);
            double entryDeal = PositionGetDouble(POSITION_PRICE_OPEN);
            ulong ticket = PositionGetTicket(i);
           
            if(entryPrice == 0){
               entryPrice = entryDeal;
            } 
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
               if(entryPrice < actualCandle.close ){
                  entryPrice = actualCandle.close;
                  closeBuyOrSell(i);
                  toBuyOrToSell(UP,ACTIVE_VOLUME,STOP_LOSS,TAKE_PROFIT);
               }
            }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
               if(entryPrice > actualCandle.close ){
                  entryPrice = actualCandle.close;
                  closeBuyOrSell(i);
                  toBuyOrToSell(DOWN,ACTIVE_VOLUME,STOP_LOSS,TAKE_PROFIT);
               }
            }
         }
      }
   }
   return entryPrice;
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

bool realizeDeals(TYPE_NEGOCIATION typeDeals, double volume, double stopLoss, double takeProfit){
   if(typeDeals != NONE){
      BordersOperation borders = normalizeTakeProfitAndStopLoss(stopLoss, takeProfit); 
      if(hasPositionOpen() == false) {
         if(typeDeals == BUY){ 
            toBuy(volume, borders.min, borders.max);
         }
         else if(typeDeals == SELL){
            toSell(volume, borders.min, borders.max);
         }
         
         if(verifyResultTrade()){
            Print("Negociação realizada com sucesso.");
            return true;
         }
       }
    }
    
    return false;
 }

void closeBuyOrSell(int position){
   ulong ticket = PositionGetTicket(position);
   tradeLib.PositionClose(ticket);
   if(verifyResultTrade()){
      Print("Negociação concluída.");
   }
}

bool toBuyOrToSell(ORIENTATION orient, double volume, double stopLoss, double takeProfit){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   return realizeDeals(typeDeal, volume, stopLoss, takeProfit);
   //getHistory();
}

bool hasPositionOpen(){
    if(PositionSelect(_Symbol) == true) {
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
   
   datetime lastBarTime = (datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
   
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

bool verifyTimeToProtection(){
   if(timeToProtection(SCHEDULE_START_PROTECTION, SCHEDULE_END_PROTECTION)){
      Print("Horario de proteção ativo");
      return false;
   }else if(!timeToProtection(SCHEDULE_START_DEALS, SCHEDULE_END_DEALS)){
      Print("Fim do tempo operacional. Encerrando Negociações");
      return false;
   }
   return true;
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

void removeDeals(){
   Print("Removendo negociações..");
   Print("Posições em aberto: ", PositionsTotal());
   while(PositionsTotal() > 0 || hasPositionOpen()){
      closeBuyOrSell(0);
   }
}
  // countDays = verifyDayTrade(timeStartedDealActual, countDays, 0);
  
double calcTotal(){
   double total = 0;
   ResultOperation resultOp;
   double result = 0;
   
   HistorySelect(0, TimeCurrent());
   ulong trades = HistoryDealsTotal();
   //Print("Total de negociações: ", trades);
   //Print("Lucro Atual: R$ ", resultOperation.liquidResult);
   
   for(uint i = 1; i <= trades; i++)  {
      ulong ticket = HistoryDealGetTicket(i);
      result = HistoryDealGetDouble(ticket,DEAL_PROFIT);    
      resultOp = getResultOperation(result);   
      total += resultOp.liquidResult; 
   }
   
   return total;
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


int getActualDay(datetime startedDatetimeRobot){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(startedDatetimeRobot, structDate);
   return (structActual.day_of_year - structDate.day_of_year);
}

double calcPoints(double val1, double val2){
   return (val1 - val2) / _Point;
}