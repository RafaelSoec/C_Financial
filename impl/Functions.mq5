//+------------------------------------------------------------------+
//|                                                    Functions.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//input int CANDLES_NUMBERS = 30;

#include "MainFunctionsBackup.mqh"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   createButton("btnInvert", 4, 24, 100, 20, CORNER_LEFT_LOWER, 10, "Arial", "Inverter", clrWhite, clrBlueViolet, clrBlueViolet, false);
   createButton("btnClose", 110, 24, 100, 20, CORNER_LEFT_LOWER, 10, "Arial", "Fechar", clrWhite, clrBlueViolet, clrBlueViolet, false);
   createButton("btnBorders", 216, 24, 100, 20, CORNER_LEFT_LOWER, 10, "Arial", "Bordas", clrWhite, clrBlueViolet, clrBlueViolet, false);
   //createButton("btnBorders", 400, 80, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Bordas", clrWhite, clrBlueViolet, clrBlueViolet, false);
   
   
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
   
  }
//+------------------------------------------------------------------+

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
//---
   // Fechar negociacões
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "btnInvert"){
         if(toInvert()){
            Alert("Negociação Invertida");
         }
      }
      else if(sparam == "btnClose"){
         closeBuyOrSell(0);
         if(verifyResultTrade()){
            Alert("Negociação fechada");
         }
      }
      else if(sparam == "btnBorders"){
         generateBorders(20);
      }
   }
}

void generateBorders(int candleNumbers){
   bool genBord = false;
   int copiedPrice = CopyRates(_Symbol,_Period,0,candleNumbers,candles);
   if(copiedPrice == candleNumbers){
      double resistance = 0;
      double support = 1000;
      for(int i = candleNumbers-1; i >= 0; i--){
         if(candles[i].close > resistance){
            resistance = candles[i].close;
         }else if(candles[i].close <  support){
            support = candles[i].close;
         }
         
         if(support != 1000 && resistance != 0){
            if(calcPoints(resistance, support) >= PONTUATION_ESTIMATE){
               drawHorizontalLine(support, TimeCurrent(), "support border", clrYellow);
               drawHorizontalLine(resistance, TimeCurrent(), "resistance border", clrYellow);
               genBord = true;
               break;
            }
         }
      }
   }
   
   if(!genBord){
      generateBorders(candleNumbers + 20);
   }
}
