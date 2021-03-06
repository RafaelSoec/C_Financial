#include <Trade\Trade.mqh>

CTrade tradeLib;

#define EQUAL "="
#define MAJOR ">"
#define MINOR "<"

#define BUY 0
#define SELL 1
#define NONE 2

#define LOW 0
#define HIGH 1
#define CLOSE 2
#define OPEN 3

enum AVERAGE_PONTUATION{
   AVERAGE_0,
   AVERAGE_5,
   AVERAGE_10,
   AVERAGE_15,
   AVERAGE_20,
   AVERAGE_25,
   AVERAGE_30,
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

input POWER BREAK_EVEN = OFF;
input POWER STOP_MOVEL = OFF;
input POWER OPERATING_ON_LIMIT = OFF;
input POWER AGAINST_CURRENT = ON;
input POWER BASED_ON_FINANCIAL_PROFIT_AND_LOSS = ON;
input AVERAGE_PONTUATION RANDOM_PONTUATION = AVERAGE_0;
input string NEGOCIATIONS_LIMIT_TIME = "17:30";
input string START_PROTECTION_TIME = "12:00";
input string END_PROTECTION_TIME = "13:00";
input double PONTUATION_ESTIMATE = 50;
input double ACTIVE_VOLUME = 1;
input int HEGHT_BUTTON_PANIC = 350;
input int WIDTH_BUTTON_PANIC = 500;
input color INDICATOR_COLOR = clrRed;
//input double TAKE_PROFIT_FINANCIAL = 12;
//input double STOP_LOSS_FINANCIAL = 6;
input double PROFIT_MAX_PER_DAY = 300;
input double LOSS_MAX_PER_DAY = 50;
input double TAKE_PROFIT = 100;
input double STOP_LOSS = 10;
input int AVALIATION_TIME = 10;
//input bool DOLAR_INDEX = true;

MqlRates candles[];
MqlTick tick;

POWER breakEven = BREAK_EVEN;
double takeProfit = (TAKE_PROFIT);
double stopLoss = (STOP_LOSS);

int contador = 0;
int pontuationEstimate;
datetime avaliationTime;
bool periodAchieved = false;
bool activeNegociation = false;
bool startedAvaliationTime = false;
bool closedNegociations = false;
bool isPossivelToSell = false;
int typeNegociation = NONE;
int maxPositionsArray = 2;
BordersOperation borders;
double profits = 0;
double losses = 0;

ResultOperation resultNegociations;

void startRobots(){
  printf("Start Robots in " +  _Symbol);
  CopyRates(_Symbol,_Period,0,maxPositionsArray,candles);
  ArraySetAsSeries(candles, true);
  createButton("BotaoPanic", WIDTH_BUTTON_PANIC, HEGHT_BUTTON_PANIC, 200, 30, CORNER_LEFT_LOWER, 12, "Calibri", "Fechar Negociacoes", clrWhite, clrRed, clrRed, false);
}

void finishRobots(){
  printf("Finish Robots in " +  _Symbol);
}

void closeBuyOrSell(){
   ulong ticket = PositionGetTicket(0);
   tradeLib.PositionClose(ticket);
   verifyResultTrade();
}

void cancelOrder(){
   ulong ticket = OrderGetTicket(0);
   tradeLib.OrderDelete(ticket);
   verifyResultTrade();
}

bool checkAvaliationTime(){
   if(AVALIATION_TIME != 0){
      periodAchieved = false;
      datetime localTime = TimeLocal(); 
      // Primeira execucao
      if(!startedAvaliationTime){
         avaliationTime = localTime + AVALIATION_TIME;
         startedAvaliationTime = true;
         periodAchieved = true;
      }
      
      //Print("Seconds Dif: ", secDiff);
      if(localTime >= avaliationTime){
         avaliationTime += AVALIATION_TIME;
         periodAchieved = true;
         //Print("Hora de avaliar.");
         return true;
      }
   }
      
   return false;
}

void decideToBuyOrSell(MqlRates& precoAtual){
   //Preço anterior maior que o atual == Hora de comprar
   if(precoAtual.close > borders.max){
      typeNegociation = SELL;
   }else if(precoAtual.close < borders.min){
      typeNegociation = BUY;
   }else{
      typeNegociation = NONE;
   }
   
   /**/
   if(AGAINST_CURRENT == ON){
      if(typeNegociation == BUY){
         typeNegociation = SELL;            
      }
      else if(typeNegociation == SELL){
         typeNegociation = BUY;
      }
   }
   
   if(typeNegociation != NONE && hasNewCandle()){
      double stopLossNormalized;
      double takeProfitNormalized;
      
      // modificação para o indice dolar DOLAR_INDEX
      if(_Digits == 3){
         stopLoss = (STOP_LOSS * 1000);
         takeProfit = (TAKE_PROFIT * 1000);  
      }else{
         stopLoss = NormalizeDouble(STOP_LOSS * _Point, _Digits);
         takeProfit = NormalizeDouble(TAKE_PROFIT * _Point, _Digits); 
      }
      
      //Instanciar TICKS
      SymbolInfoTick(_Symbol, tick);
      if(OPERATING_ON_LIMIT == OFF){
         if(PositionSelect(_Symbol) == false){
            if(typeNegociation == BUY){
               stopLossNormalized = NormalizeDouble((tick.ask - stopLoss), _Digits);
               takeProfitNormalized = NormalizeDouble((tick.ask + takeProfit), _Digits);
               tradeLib.Buy(ACTIVE_VOLUME, _Symbol, NormalizeDouble(tick.ask,_Digits), stopLossNormalized, takeProfitNormalized);
            }
            else if(typeNegociation == SELL){
               stopLossNormalized = NormalizeDouble((tick.bid + stopLoss), _Digits);
               takeProfitNormalized = NormalizeDouble((tick.bid - takeProfit), _Digits);
               tradeLib.Sell(ACTIVE_VOLUME, _Symbol, NormalizeDouble(tick.bid,_Digits), stopLossNormalized, takeProfitNormalized);
            }
            verifyResultTrade();
            breakEven = OFF;
         }
         
         if(PositionSelect(_Symbol) == true){
            if(BREAK_EVEN == ON){
               double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               double slPrice = PositionGetDouble(POSITION_SL);
               double tpPrice = PositionGetDouble(POSITION_TP);
               double averagePrice = (entryPrice + tpPrice) / 2;
               
               
               drawHorizontalLine(averagePrice, "Breakeven", clrYellow);
               if(tick.last >= averagePrice && breakEven == OFF){
                  tradeLib.PositionModify(PositionGetTicket(0),entryPrice,tpPrice);
                  drawHorizontalLine(averagePrice, "BreakevenUpdated", clrYellowGreen);
                  breakEven = ON;
               }
            }
            
            if(STOP_MOVEL == ON){
               double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               double slPrice = PositionGetDouble(POSITION_SL);
               double tpPrice = PositionGetDouble(POSITION_TP);
               double diffSl = (stopLoss * _Point);
               double newSlPrice;
               double diffPriceTick;
                 
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                   newSlPrice = NormalizeDouble((tick.last - diffSl), _Digits);
                   diffPriceTick = (tick.last - slPrice);
               }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                   newSlPrice = NormalizeDouble((tick.last + diffSl), _Digits);
                   diffPriceTick = (slPrice - tick.last);
               }
               
               drawHorizontalLine(newSlPrice, "StopMovel", clrDarkViolet);
               // slPrice != newSlPrice = o preço precisa variar para que eu entre nessa condicao novamente
               if( diffPriceTick > diffSl  && slPrice != newSlPrice){
                  tradeLib.PositionModify(PositionGetTicket(0),newSlPrice,tpPrice);
                  drawHorizontalLine(newSlPrice, "StopMovelUpdated", clrViolet);
               }
            }
            
            if(BASED_ON_FINANCIAL_PROFIT_AND_LOSS == ON){
               double result = PositionGetDouble(POSITION_PROFIT);
               if(result != 0){
                    Print("Lucro Atual: R$ ", result);
                  
                  /*  STOP_LOSS_FINANCIAL AND TAKE_PROFIT_FINANCIAL  - DONT WORK
                   if(result <= -STOP_LOSS_FINANCIAL){
                     Print("Limite de perdas atingido -> R$ ", STOP_LOSS_FINANCIAL);
                     closeBuyOrSell();
                   }else if(result >= TAKE_PROFIT_FINANCIAL) {
                     Print("Limite de ganho atingido -> R$ ", TAKE_PROFIT_FINANCIAL);
                     closeBuyOrSell();
                   }
                   
                  //Verificar fracao de tempo de execucao dos candles                  
                  if(periodAchieved){
                     if(MathAbs(result) < (STOP_LOSS_FINANCIAL * 0.01)){
                        Print("Não foi atingido um valor de perda ou ganho que justifique a transação. Valor alcançado: R$ ", (STOP_LOSS_FINANCIAL * -0.01));
                        closeBuyOrSell();
                     }else if(MathAbs(result) < (TAKE_PROFIT_FINANCIAL * 0.01)) { 
                        Print("Não foi atingido um valor de perda ou ganho que justifique a transação. Valor alcançado: R$ ", (TAKE_PROFIT_FINANCIAL * 0.01));
                        closeBuyOrSell();
                     }
                  }  
                  */
               }
            }
         
            if(timeToProtection(NEGOCIATIONS_LIMIT_TIME, MAJOR) ){
               Print("Fim do tempo operacional. Encerrando Negociações");
               closeBuyOrSell();
               closedNegociations = true;
            }
         }
       }else{
         if(OrderSelect(OrderGetTicket(0)) == false){
            double sellNvl;
             // utiliza o candle anterior
            if(typeNegociation == BUY){
               sellNvl = NormalizeDouble((candles[0].low - (takeProfit * _Point)), _Digits); 
               takeProfitNormalized = NormalizeDouble((sellNvl - (stopLoss * _Point)), _Digits);
               stopLossNormalized = NormalizeDouble((sellNvl + (takeProfit * _Point)), _Digits);
               tradeLib.SellLimit(ACTIVE_VOLUME,sellNvl,_Symbol, takeProfitNormalized, stopLossNormalized);
            }else if(typeNegociation == SELL){
               sellNvl = NormalizeDouble((candles[0].high + (takeProfit * _Point)), _Digits); 
               takeProfitNormalized = NormalizeDouble((sellNvl + (stopLoss * _Point)), _Digits);
               stopLossNormalized = NormalizeDouble((sellNvl - (takeProfit * _Point)), _Digits);
               tradeLib.SellLimit(ACTIVE_VOLUME,sellNvl,_Symbol, takeProfitNormalized, stopLossNormalized);
            }
         }
      
         if(OrderSelect(OrderGetTicket(0)) == true){
            if(timeToProtection(NEGOCIATIONS_LIMIT_TIME, MAJOR) || timeToProtection(NEGOCIATIONS_LIMIT_TIME, EQUAL)){
               Print("Fim do tempo operacional. Encerrando Ordens");
               cancelOrder();
            }
         }
      }
      printf("Preço Fechamento atual: R$ %s", DoubleToString(precoAtual.close,6));
      printf("Preço Abertura atual: R$ %s", DoubleToString(precoAtual.open,6));
      
      getHistory();
   }
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

void getHistory(){
   ResultOperation resultOperation, resultOp;
   double result = 0;
   
   HistorySelect(0, TimeCurrent());
   ulong trades = HistoryDealsTotal();
   Print("Total de negociações: ", trades);
   
   for(int i = 1; i <= trades; i++)  {
      ulong tick_n = HistoryDealGetTicket(i);
      result = HistoryDealGetDouble(tick_n,DEAL_PROFIT);    
      resultOp = getResultOperation(result);
      resultOperation.total += resultOp.total;
      resultOperation.losses += resultOp.losses;
      resultOperation.profits += resultOp.profits;
      resultOperation.liquidResult += resultOp.liquidResult;
      resultOperation.profitFactor += resultOp.profitFactor;  
   }
   
   Print("Lucro Atual: R$ ", resultOperation.liquidResult);
   if(resultOperation.liquidResult >= PROFIT_MAX_PER_DAY || resultOperation.liquidResult <= -LOSS_MAX_PER_DAY ) {
     Print("Limite atingido por dia -> R$ ", resultOperation.liquidResult);
     closedNegociations = true;
   }     
       
   Comment("Trades: " + IntegerToString(trades), 
   " Profits: " + DoubleToString(resultOperation.profits, 2), 
   " Losses: " + DoubleToString(resultOperation.losses, 2), 
   " Profit Factor: " + DoubleToString(resultOperation.profitFactor, 2), 
   " Liquid Result: " + DoubleToString(resultOperation.liquidResult, 2));
}

void verifyResultTrade(){
   if(tradeLib.ResultRetcode() == TRADE_RETCODE_PLACED || tradeLib.ResultRetcode() == TRADE_RETCODE_DONE){
      printf("Ordem de %s executada com sucesso.");
   }else{
      Print("Erro de execução de ordem", GetLastError());
      ResetLastError();
   }
}

bool timeToProtection(string protectionTime, string oper){
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

void startNegociations(){
   checkAvaliationTime();
   if(timeToProtection(START_PROTECTION_TIME, MAJOR) && timeToProtection(END_PROTECTION_TIME, MINOR)){
      //printf("Horario de proteção ativo");
   }else{
      MqlRates precos[2];
      //precos[1] -- Posicao atual
      //precos[0] -- Posicao anterior
      //ArraySetAsSeries(precos, true);
      int copied = CopyRates(_Symbol,_Period,0,2,precos);
      
   //--- go trading only for first ticks of new bar
      if(copied != 2){
         Print("Preços não recuperados");
         return;
      }else{
         MqlRates precoAnt = precos[0];
         MqlRates precoAtual = precos[1];
     
         drawHorizontalLine(precoAtual.close, "PrecoFechamentoAtual", clrAqua);
         drawHorizontalLine(precoAtual.open, "PrecoAberturaAtual", clrPaleGreen);
         
         if(periodAchieved){
            drawBorders(precoAtual);
         }
         decideToBuyOrSell(precoAtual);
      }     
   }
}

void drawBorders(MqlRates& precoAtual){
   double precoFechamento = precoAtual.close;
   
   if(RANDOM_PONTUATION != AVERAGE_0){
      BordersOperation averagePontuation = calculateAveragePontuation(RANDOM_PONTUATION);
      double averagePointed = ((averagePontuation.max-averagePontuation.min));
      borders.max = MathAbs(averagePointed + precoFechamento);
      borders.min = MathAbs(averagePointed - precoFechamento);
   }else{
      borders.max = MathAbs(_Point * PONTUATION_ESTIMATE + precoFechamento);
      borders.min = MathAbs(_Point * PONTUATION_ESTIMATE - precoFechamento);
   }
   
   drawHorizontalLine(borders.max, "BorderMax", INDICATOR_COLOR);
   drawHorizontalLine(borders.min, "BorderMin", INDICATOR_COLOR);
   //Print("Atualização de Bordas");
}

void drawHorizontalLine(double price, string nameLine, color indColor){
   ObjectCreate(_Symbol,nameLine,OBJ_HLINE,0,0,price);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
   ObjectMove(_Symbol,nameLine,0,0,price);
}

void drawVerticalLine(datetime time, string nameLine, color indColor){
   ObjectCreate(_Symbol,nameLine,OBJ_VLINE,0,time,0);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
}

void createButton(string nameLine, int xx, int yy, int largura, int altura, int canto, int tamanho, int fonte, string text, long corTexto, long corFundo, long corBorda, bool oculto){
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
   ObjectSetInteger(0,nameLine,OBJPROP_HIDDEN, oculto);
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

void removeNegociations(){
   while(OrdersTotal() > 0){
      cancelOrder();
   }
   while(PositionsTotal() > 0){
      closeBuyOrSell();
   }
         
}