//+------------------------------------------------------------------+
//|                                                    PeakRobot.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

CTrade tradeLib;

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


struct InfoDeal {
   double price;
   ulong ticket;
   datetime timeStartDeal;
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

struct SelectedPrices {
   MqlRates last;
   MqlRates secondLast;
};


input POWER TESTING_DAY = ON;
input POWER AGAINST_CURRENT = ON;
input POWER SCALPER = ON;
input POWER STOP_MOVEL = ON;
input POWER BASED_ON_FINANCIAL_PROFIT_AND_LOSS = ON;
input AVERAGE_PONTUATION RANDOM_PONTUATION = AVERAGE_0;
input int MINUTES_AVAL = 15;
input int PONTUATION_ESTIMATE = 100;
input double PROFIT_MAX_PER_DAY = 300.0;
input double LOSS_MAX_PER_DAY = 50.0;
input int TAKE_PROFIT = 110;
input int STOP_LOSS = 40;
input double ACTIVE_VOLUME = 1.0;
input int BARS_NUM = 4;
input int HEGHT_BUTTON_PANIC = 350;
input int WIDTH_BUTTON_PANIC = 500;
input string NEGOCIATIONS_LIMIT_TIME = "17:30";
input string START_PROTECTION_TIME = "12:00";
input string END_PROTECTION_TIME = "13:00";

MqlTick tick;

double takeProfit = (TAKE_PROFIT);
double stopLoss = (STOP_LOSS);

bool hasDeal = false;

int contador = 0;
int countDays = 1;
bool advanceDeal = false;
datetime avaliationTime;
bool periodAchieved = false;
int printClosedNeg = false;
bool activeDeal = false;
bool startedAvaliationTime = false;
SelectedPrices selectedPrices;
datetime dateClosedDeal;
bool closedDeals = false;
bool isPossivelToSell = false;
int maxPositionsArray = 2;
BordersOperation borders;
bool waitNewPeriod = false;
double profits = 0;
double losses = 0;
InfoDeal infoDeal;
datetime timeStarted;
   
bool activatedPeakRobot = false;
bool activatedBorderRobot = false;
int printTimeProtect = true;
int printEndTimeDeal = true;
ResultOperation resultDeals;
double percentProfitOrLoss = 0.4;
double percentPontuationEstimate = 0.6;
datetime timeDealStart = 0;
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
      if(waitNewPeriod == false){
         activatePeakRobotPeak();
      }else{
         if(hasNewCandle()){
            activatePeakRobotPeak();
         }
      }
  }
//+------------------------------------------------------------------+

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

void activatePeakRobotPeak(){
   MqlRates precos[3];
   int copiedPrice = CopyRates(_Symbol,_Period,0,3,precos);
   if(copiedPrice == 3 && precos[0].high > 0 && precos[0].low > 0 && precos[1].high > 0 && precos[1].low > 0){
      double pointsH = (((precos[0].high + precos[1].high) / 2) - precos[2].high) / _Point;
      double pointsP = (((precos[0].low + precos[1].low) / 2) - precos[2].low) / _Point;
      
      if(hasDeal == false){
         if((pointsH) >= PONTUATION_ESTIMATE){
            realizeDealsPeak(SELL);
            waitNewPeriod = true;
         }else if((pointsP) >= PONTUATION_ESTIMATE){
            realizeDealsPeak(BUY);
            waitNewPeriod = true;
         }
      }else{
       /*
         double max  = MathAbs(precos[1].high + precos[1].close)/2;
         double min  = MathAbs(precos[1].low + precos[1].close)/2;
         max = (max > min ? max : min);
         if(precos[2].close >= max){
            closeBuyOrSell();
            hasDeal = false;
            waitNewPeriod = false;
         }
         */
            closeBuyOrSell();
            hasDeal = false;
            waitNewPeriod = false;
      }
   }
}

void realizeDealsPeak(TYPE_NEGOCIATION typeDeals){
   /**/
   if(AGAINST_CURRENT == ON){
      if(typeDeals == BUY){
         typeDeals = SELL;            
      }
      else if(typeDeals == SELL){
         typeDeals = BUY;
      }   
   }
   
   if(STOP_LOSS != 0 || TAKE_PROFIT != 0){
      if(_Digits == 3){
         stopLoss = (STOP_LOSS * 1000);
         takeProfit = (TAKE_PROFIT * 1000);  
      }else{
         stopLoss = NormalizeDouble((STOP_LOSS * _Point), _Digits);
         takeProfit = NormalizeDouble((TAKE_PROFIT * _Point), _Digits); 
      }
   }
   
   if(typeDeals != NONE){  
      if(hasPositionOpen(false)) {
         //Instanciar TICKS
         SymbolInfoTick(_Symbol, tick);
         if(typeDeals == BUY){
            double stopLossNormalized = NormalizeDouble((tick.ask - stopLoss), _Digits); 
            tradeLib.Buy(ACTIVE_VOLUME, _Symbol, NormalizeDouble(tick.ask,_Digits), 0, 0);
         }
         else if(typeDeals == SELL){  
             double stopLossNormalized = NormalizeDouble((tick.bid + stopLoss), _Digits);
            tradeLib.Sell(ACTIVE_VOLUME, _Symbol, NormalizeDouble(tick.bid,_Digits), 0, 0);
         }
         
         if(verifyResultTrade()){
            //Salvar informacoes da negociação iniciado
            infoDeal.price = PositionGetDouble(POSITION_PRICE_CURRENT);
            infoDeal.ticket = PositionGetTicket(0);
            infoDeal.timeStartDeal = TimeLocal();
            hasDeal = true;
         }
       }
    }
 }

void closeBuyOrSell(){
   ulong ticket = PositionGetTicket(0);
   tradeLib.PositionClose(ticket);
   verifyResultTrade();
}

bool hasPositionOpen(bool posBool){
    if(PositionSelect(_Symbol) == posBool) {
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
   
   resultDeals.losses = resultOperation.losses;
   resultDeals.profits = resultOperation.profits;
   resultDeals.profitFactor = resultOperation.profitFactor;
   resultDeals.liquidResult = resultOperation.liquidResult;
      
}