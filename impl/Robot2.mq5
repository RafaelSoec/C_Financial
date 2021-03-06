//+------------------------------------------------------------------+
//|                                                       Robot2.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "robot2Functions.mqh"

int printClosedNeg = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- criamos um temporizador com um período de 1 segundo
   //EventSetTimer(1);
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
   //EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
//---
   if(!closedNegociations){
      startNegociations();
   }else{
      if(!printClosedNeg){
         removeNegociations();
         Print("Negociações Encerradas para o dia: ", TimeToString(dateClosedNegociation, TIME_DATE));
         printClosedNeg = true;
      }
         
      datetime actualTime = TimeCurrent();
      MqlDateTime structDate, structActual;
      TimeToStruct(actualTime, structActual);
      TimeToStruct(dateClosedNegociation, structDate);
      if(structDate.day_of_year != structActual.day_of_year){
         printClosedNeg = false;
         closedNegociations = false;
         Print("Negociações Abertas para o dia: ", TimeToString(actualTime, TIME_DATE));
      }
   }
   
}
  
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
//void OnTimer(){
//   contador++;
//}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
//---
   // Fechar negociacões
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "BotaoPanic"){
         if(!closedNegociations){
            removeNegociations();
            Alert("Negociações finalizadas");
         }
      }
   }
}
//+------------------------------------------------------------------+
