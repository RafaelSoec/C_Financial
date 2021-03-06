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


struct ResultOperation {
   double total;
   double profits;
   double losses;
   double liquidResult;
   double profitFactor;
};

struct BordersOperation {
   double max;
   double min;
};

struct PeriodProtectionTime {
   string dealsLimitProtection;
   string endProtection;
   string startProtection;
};

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


bool activeStopMovel(MqlRates& prevCandle, MqlRates& decisionCandle, MqlRates& actualCandle, bool isFirst){
   if(hasPositionOpen() == true){
      double tpPrice = PositionGetDouble(POSITION_TP);
      double entryDeal = PositionGetDouble(POSITION_PRICE_OPEN);
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
         if(entryDeal < actualCandle.open ){
            if(prevCandle.close < decisionCandle.close){
               if(isFirst == true){
                  tradeLib.PositionModify(PositionGetTicket(0),0, tpPrice);
               }else{
                  tradeLib.PositionModify(PositionGetTicket(0),decisionCandle.low, tpPrice);
               }
               return false;
            }
         }
      }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
         if(entryDeal > actualCandle.open ){
            if(prevCandle.close > decisionCandle.close){
               if(isFirst == true){
                  tradeLib.PositionModify(PositionGetTicket(0),0, tpPrice);
               }else{
                  tradeLib.PositionModify(PositionGetTicket(0),decisionCandle.high,tpPrice);
               }
               return false;
            }
         }
      }
   }
   
   return true;
}

/*void activeOpenEnd(MqlRates& prevCandle, MqlRates& actualCandle, MqlRates& decisionCandle){
   double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
      if(entryPrice < actualCandle.open ){
         if(prevCandle.close < decisionCandle.close){
            closeBuyOrSell();
            toBuyOrToSell(UP,ACTIVE_VOLUME,STOP_LOSS,TAKE_PROFIT);
         }
      }
   }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
      if(entryPrice > actualCandle.open ){
         if(prevCandle.close > decisionCandle.close){
            closeBuyOrSell();
            toBuyOrToSell(DOWN,ACTIVE_VOLUME,STOP_LOSS,TAKE_PROFIT);
         }
      }
   }
}*/

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

void toBuy(int volume, double stopLoss, double takeProfit){
   datetime actualTime = TimeCurrent();
   //Instanciar TICKS
   MqlTick tick;
   SymbolInfoTick(_Symbol, tick);
   double stopLossNormalized = NormalizeDouble((tick.ask - stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.ask + takeProfit), _Digits);
   tradeLib.Buy(volume, _Symbol, NormalizeDouble(tick.ask,_Digits), stopLossNormalized, takeProfitNormalized); 
}

void toSell(int volume, double stopLoss, double takeProfit){
   datetime actualTime = TimeCurrent();
   MqlTick tick;
   SymbolInfoTick(_Symbol, tick);
   double stopLossNormalized = NormalizeDouble((tick.bid + stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.bid - takeProfit), _Digits);
   tradeLib.Sell(volume, _Symbol, NormalizeDouble(tick.bid,_Digits), stopLossNormalized, takeProfitNormalized);   
}

bool realizeDeals(TYPE_NEGOCIATION typeDeals, int volume, double stopLoss, double takeProfit){
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
       }else{
            closeBuyOrSell();
       }
    }
    
    return false;
 }

void closeBuyOrSell(){
   ulong ticket = PositionGetTicket(0);
   tradeLib.PositionClose(ticket);
   if(verifyResultTrade()){
      Print("Negociação concluída.");
   }
}

bool toBuyOrToSell(ORIENTATION orient, int volume, double stopLoss, double takeProfit){
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

BordersOperation drawBorders(MqlRates& precoAtual, double pontuationEstimateHigh, double pontuationEstimateLow){
   double precoFechamento = precoAtual.close;
   BordersOperation borders;
   
   borders.max = MathAbs(_Point * pontuationEstimateHigh + precoFechamento);
   borders.min = MathAbs(_Point * pontuationEstimateLow - precoFechamento);
   drawHorizontalLine(borders.max, 0, "BorderMax", clrRed);
   drawHorizontalLine(borders.min, 0, "BorderMin", clrRed);
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
   ObjectCreate(_Symbol,nameLine,OBJ_HLINE,0,time,price);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
   ObjectMove(_Symbol,nameLine,0,time,price);
}

void drawArrow(datetime time, string nameLine, double price, ORIENTATION orientation){
   if(orientation == UP){
      ObjectCreate(_Symbol,nameLine,OBJ_ARROW_UP,0,time,price);
   }else{
      ObjectCreate(_Symbol,nameLine,OBJ_ARROW_DOWN,0,time,price);
   }
}

void drawVerticalLine(datetime time, string nameLine, color indColor){
   ObjectCreate(_Symbol,nameLine,OBJ_VLINE,0,time,0);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
}

void createButton(string nameLine, int xx, int yy, int largura, int altura, int canto, int tamanho, string fonte, string text, long corTexto, long corFundo, long corBorda, bool oculto){
   ObjectCreate(_Symbol,nameLine,OBJ_BUTTON,0,0,0);
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

bool verifyTimeToProtection(PeriodProtectionTime& periods){
   if(timeToProtection(periods.startProtection, MAJOR) && timeToProtection(periods.endProtection, MINOR)){
      Print("Horario de proteção ativo");
      return false;
   }else if(timeToProtection(periods.dealsLimitProtection, MAJOR) ){
      Print("Fim do tempo operacional. Encerrando Negociações");
      return false;
   }
   return true;
}


bool timeToProtection(string protectionTime, OPERATOR oper){
   string actualTime = TimeToString(TimeCurrent(),TIME_MINUTES);
   
   if(protectionTime == "00:00"){
      return false;
   }else{
      if(oper == MINOR){
         if(actualTime <= protectionTime){
            return true;
         }
      }
      if(oper == MAJOR){
         if(actualTime >= protectionTime){
            return true;
         }
      }else{
         if(actualTime == protectionTime){
            return true;
         }
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
      closeBuyOrSell();
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