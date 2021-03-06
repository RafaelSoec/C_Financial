//+------------------------------------------------------------------+
//|                                                MacroAnalisys.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

input  ENUM_MA_METHOD MODE_AVERAGES = MODE_SMA;

#include "MainFunctionBackup.mqh"

datetime startedDatetimeMacroAnalisysRobot = 0;
double averageML[], averageMH[], averageMD[], averageWeekly[], entryPriceAnalisys = 0, channelSizeAnalisys = PONTUATION_ESTIMATE, lastMovimentPrice;
int handleW, handleM, handleD, handleH, handle8H, handleMin, handle5Min, handle15Min, handle30Min, handle200, indexMax = 0, indexMin = 0, countCandles = 0;
bool crossBorderAnalisys = false, uniqueEntry = false;

ORIENTATION orientationAnalisys = MEDIUM, orientationTendencyMacro = MEDIUM;
BordersOperation monthlyBorders, weeklyBorders, dailyBorders, hour8Borders, hourBorders, min15Borders, selectedBordersAnalisys, selectedSuperiorBordersAnalisys, selectedBordersDealAnalisys;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
     instanciateBorder(selectedSuperiorBordersAnalisys);
     instanciateBorder(selectedBordersAnalisys);
     instanciateBorder(monthlyBorders);
     instanciateBorder(weeklyBorders);
     instanciateBorder(dailyBorders);
     instanciateBorder(hour8Borders);
     instanciateBorder(hourBorders);
     instanciateBorder(min15Borders);
     
     
     handleM = iMA(_Symbol,PERIOD_MN1,1,0,MODE_AVERAGES,PRICE_CLOSE);
     handleW = iMA(_Symbol,PERIOD_W1,1,0,MODE_AVERAGES,PRICE_CLOSE);
     handleD = iMA(_Symbol,PERIOD_D1,1,0,MODE_AVERAGES,PRICE_CLOSE);
     handleH = iMA(_Symbol,PERIOD_H1,1,0,MODE_AVERAGES,PRICE_CLOSE);
    // handle8H = iMA(_Symbol,PERIOD_H2,1,0,MODE_AVERAGES,PRICE_CLOSE);
   ///  handleMin = iMA(_Symbol,PERIOD_M1,1,0,MODE_AVERAGES,PRICE_CLOSE);
   //  handle5Min = iMA(_Symbol,PERIOD_M5,1,0,MODE_AVERAGES,PRICE_CLOSE);
     handle15Min = iMA(_Symbol,PERIOD_M15,1,0,MODE_AVERAGES,PRICE_CLOSE);
  //   handle30Min = iMA(_Symbol,PERIOD_M30,1,0,MODE_AVERAGES,PRICE_CLOSE);
     handle200 = iMA(_Symbol,PERIOD_M1,200,0,MODE_AVERAGES,PRICE_CLOSE);
     
     
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

   if(verifyTimeToProtection()){
     if(hasNewCandle()){
         int copiedPrice = CopyRates(_Symbol,_Period,0,3,candles);
         if(copiedPrice == 3){
            isPossibleStartDeals(candles[2].close);
            if(countCandles <= 0 ){
               if(hasPositionOpen()){
                  activeStopMovelPerPoints(STOP_LOSS, candles[2].close);
               }else{
                  if(!uniqueEntry){
                     channelSizeAnalisys = 0;
                     verifyCrossedBorder(candles[0], candles[1]);
                     decideToBuyOrSellAnalisys(candles[2]);
                  }
               }
            } 
            countCandles--;
        }
     }  
   }else{
     closeBuyOrSell(0);
   }
}


void verifyCrossedBorder( MqlRates& prevCandle, MqlRates& actualCandle){
   if(crossBorderAnalisys == false && selectedBordersAnalisys.instantiated == true){
      if(selectedBordersAnalisys.orientation == UP){
         if(prevCandle.close > selectedBordersAnalisys.max && actualCandle.close > selectedBordersAnalisys.max){ 
            if(selectedSuperiorBordersAnalisys.orientation == selectedBordersAnalisys.orientation){
               crossBorderAnalisys = true;
               orientationAnalisys = UP;
            }else{
               crossBorderAnalisys = true;
               orientationAnalisys = DOWN;
            }
         }
      }else if(selectedBordersAnalisys.orientation == DOWN){
         if(prevCandle.close < selectedBordersAnalisys.min && actualCandle.close < selectedBordersAnalisys.min){
            if(selectedSuperiorBordersAnalisys.orientation == selectedBordersAnalisys.orientation){
               crossBorderAnalisys = true;
               orientationAnalisys = DOWN;
            }else{
               crossBorderAnalisys = true;
               orientationAnalisys = UP;
            }
         }
      }else{
         orientationAnalisys = MEDIUM;
      }
   }
}



void decideToBuyOrSellAnalisys(MqlRates& actualCandle){
   if(crossBorderAnalisys == true){
      double average[];
      if(orientationAnalisys != MEDIUM && CopyBuffer(handle200,0,0,1,average) == 1){
         double diff = calcPoints(actualCandle.close, average[0]);
         
         if(diff > PONTUATION_ESTIMATE){
            if(average[0] > actualCandle.close){
               toBuyOrToSellAnalisys(actualCandle, DOWN, STOP_LOSS, TAKE_PROFIT);
            }else if(average[0] < actualCandle.close){
               toBuyOrToSellAnalisys(actualCandle, UP, STOP_LOSS, TAKE_PROFIT);
            }
         }
      }
   }
}

void toBuyOrToSellAnalisys(MqlRates& actualCandle, ORIENTATION orient, double stopLoss, double takeProfit){
  toBuyOrToSell(orient,ACTIVE_VOLUME,stopLoss,takeProfit);
  if(verifyResultTrade()){ 
      crossBorderAnalisys = false; 
      selectedBordersDealAnalisys = selectedBordersAnalisys;
      updateBorderAnalisys(actualCandle.close); 
      countCandles = WAIT_CANDLES;
      uniqueEntry = true;
  }
}
  

bool isPossibleStartDeals(double closePrice){
   if(isNewDay(startedDatetimeMacroAnalisysRobot)){
      instanciateBorder(selectedSuperiorBordersAnalisys);
      instanciateBorder(selectedBordersAnalisys);
      instanciateBorder(monthlyBorders);
      instanciateBorder(weeklyBorders);
      instanciateBorder(dailyBorders);
      instanciateBorder(hour8Borders);
      instanciateBorder(hourBorders);
      instanciateBorder(min15Borders);
      
      uniqueEntry = false;
      startedDatetimeMacroAnalisysRobot = TimeCurrent();
      drawVerticalLine(startedDatetimeMacroAnalisysRobot, "startday" + TimeToString(startedDatetimeMacroAnalisysRobot), clrYellow);
      
      closeBuyOrSell(0);
      drawBordersAnalisys();
      updateBorderAnalisys(closePrice);
      
      return true;
   }
   
   return false;
}

void drawBordersAnalisys(){
   defineBordersAnalisys(monthlyBorders,handleM, "monthly", clrRed);
   defineBordersAnalisys(weeklyBorders,handleW, "weekly", clrYellow);
   defineBordersAnalisys(dailyBorders,handleD, "daily", clrAquamarine);
   defineBordersAnalisys(hourBorders,handleH, "hour", clrGreenYellow);
   //defineBordersAnalisys(hour8Borders,handle8H, "hour2", clrBlueViolet);
}

void updateBorderAnalisys(double closePrice){
   if(selectedBordersAnalisys.instantiated == false || closePrice > selectedBordersAnalisys.max || closePrice < selectedBordersAnalisys.min){
      instanciateBorder(selectedBordersAnalisys);
      instanciateBorder(selectedSuperiorBordersAnalisys);
      if(closePrice <= hourBorders.max && closePrice >= hourBorders.min){
         selectedBordersAnalisys = hourBorders;
         selectedBordersAnalisys.instantiated = true;
         selectedBordersAnalisys.central = recoveryMedianValue(closePrice, hourBorders, dailyBorders, weeklyBorders, monthlyBorders);
         selectedSuperiorBordersAnalisys = dailyBorders;
      }else if(closePrice <= dailyBorders.max && closePrice >= dailyBorders.min){
         selectedBordersAnalisys = dailyBorders;
         selectedBordersAnalisys.instantiated = true;
         selectedBordersAnalisys.central = recoveryMedianValue(closePrice, dailyBorders, hourBorders, weeklyBorders, monthlyBorders);
         selectedSuperiorBordersAnalisys = weeklyBorders;
      }else if(closePrice <= weeklyBorders.max && closePrice >= weeklyBorders.min){
         selectedBordersAnalisys = weeklyBorders;
         selectedBordersAnalisys.instantiated = true;
         selectedBordersAnalisys.central = recoveryMedianValue(closePrice, weeklyBorders, hourBorders, dailyBorders, monthlyBorders);
         selectedSuperiorBordersAnalisys = monthlyBorders;
      }else if(closePrice <= monthlyBorders.max && closePrice >= monthlyBorders.min){
         selectedBordersAnalisys = monthlyBorders;
         selectedBordersAnalisys.instantiated = true;
         selectedBordersAnalisys.central = recoveryMedianValue(closePrice, monthlyBorders, dailyBorders, weeklyBorders, hourBorders);
         selectedSuperiorBordersAnalisys.max = monthlyBorders.max + (PONTUATION_ESTIMATE * _Point);
         selectedSuperiorBordersAnalisys.min = monthlyBorders.min - (PONTUATION_ESTIMATE * _Point);
      }
   }
}
//+------------------------------------------------------------------+

double recoveryMedianValue(double closePrice, BordersOperation& bord0, BordersOperation& bord1, BordersOperation& bord2, BordersOperation& bord3){
/* */
   double ret = -1;
   if(bord0.min < bord1.max && bord0.max > bord1.max){
      ret = bord1.max;
   }
   if(bord0.min < bord1.min && bord0.max > bord1.min){
      if(ret > 0 && calcPoints(closePrice, bord1.min) < calcPoints(closePrice, ret)){
         ret = bord1.min;
      }else{
         ret = bord1.min;
      }
   }
   if(bord0.min < bord2.max && bord0.max > bord2.max){
      if(ret > 0 && calcPoints(closePrice, bord2.max) < calcPoints(closePrice, ret)){
         ret = bord2.max;
      }else{
         ret = bord2.max;
      }
   }
   if(bord0.min < bord2.min && bord0.max > bord2.min){
      if(ret > 0 && calcPoints(closePrice, bord2.min) < calcPoints(closePrice, ret)){
         ret = bord2.min;
      }else{
         ret = bord2.min;
      }
   }
   if(bord0.min < bord3.max && bord0.max > bord3.max){
      if(ret > 0 && calcPoints(closePrice, bord3.max) < calcPoints(closePrice, ret)){
         ret = bord3.max;
      }else{
         ret = bord3.max;
      }
   }
   if(bord0.min < bord3.min && bord0.max > bord3.min){
      if(ret > 0 && calcPoints(closePrice, bord3.min) < calcPoints(closePrice, ret)){
         ret = bord3.min;
      }else{
         ret = bord3.min;
      }
   }
   
   return ret;   
}

void defineBordersAnalisys(BordersOperation& borders, int handle, string nameLine, color clr){
   if(borders.instantiated == false){
      int period = PERIOD, down = 0, up = 0;
      double average[];
      
      if(handle < PERIOD){
         period = handle;
      }
      if(CopyBuffer(handle,0,0,period,average) == period){
         indexMax=ArrayMaximum(average,0,handle); // máximo em Alta
         indexMin=ArrayMinimum(average,0,handle);  // mínimo em Baixa
         borders.max = average[indexMax];
         borders.min = average[indexMin];
         borders.instantiated = true;
         
         double lastPrice = average[period-1];
         double pointsMax  = calcPoints(lastPrice, borders.min);
         double pointsMin  = calcPoints(lastPrice, borders.max);
         
         if(pointsMax > (pointsMin)){
            borders.orientation = UP;
            Print("UP");
         }else if(pointsMin > (pointsMax)){
            borders.orientation = DOWN;
            Print("DOWN");
         }else{
            borders.orientation = MEDIUM;
            Print("MEDIUM");
         }
         
         datetime actualTime = TimeCurrent();
         drawHorizontalLine( borders.max, actualTime, nameLine + "-max", clr);
         drawHorizontalLine( borders.min, actualTime, nameLine + "-min", clr);
      }
   }
}

void trailingStop(double priceClose){
   double points = calcPoints(selectedBordersDealAnalisys.max, selectedBordersDealAnalisys.min);
   double stopLoss = PositionGetDouble(POSITION_SL);
   double takeProfit = PositionGetDouble(POSITION_TP);
   double entry = PositionGetDouble(POSITION_PRICE_OPEN);
   double newStopLoss = 0, newEntry = 0;
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){ 
      newEntry = entry - (PONTUATION_ESTIMATE * _Point);
      if(priceClose < newEntry && stopLoss > entry){
        tradeLib.PositionModify(PositionGetTicket(0), entry - (PONTUATION_ESTIMATE * 0.1 * _Point), takeProfit);
        if(verifyResultTrade()){ 
            Print("Moving stop");
        }
      }
      if(stopLoss <= entry){
       //  activeStopMovelPerPoints(PONTUATION_ESTIMATE, priceClose);
      }
   }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
      newEntry = entry + (PONTUATION_ESTIMATE * _Point);
      if(priceClose > newEntry && stopLoss < newEntry){
        tradeLib.PositionModify(PositionGetTicket(0), entry + (PONTUATION_ESTIMATE * 0.1 * _Point), takeProfit);
        if(verifyResultTrade()){ 
            Print("Moving stop");
        }
      }
      if(stopLoss >= entry){
        // activeStopMovelPerPoints(PONTUATION_ESTIMATE, priceClose);
      }
   }
}