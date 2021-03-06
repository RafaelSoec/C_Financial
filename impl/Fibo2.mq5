//+------------------------------------------------------------------+
//|                                                   Fibonnacci.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"

input double INIT_POINT = 0;
input double END_POINT = 0;

double initPoint = INIT_POINT;
double endPoint = END_POINT;

int countCrossBorder = 0;
int maxFibonacciValue = 9;
double pointsMaxFibonacci = 50;
datetime startedDatetimeFibonacciRobot;
BordersOperation selectedBordersFibonacci;
ORIENTATION orientationMacroFibonacci = MEDIUM;
bool supportAndResistenceAreasDrawed = false;
bool generateNewLinesFibonacci = true;
double fiboPoints[10] = {0, 23.6, 38.2, 50, 61.8, 100, 161.8, 261.8, 432.6, 685.4};
double fiboValues[10];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   startedDatetimeFibonacciRobot = TimeCurrent();
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
void OnTick() {  
  // if(hasNewCandle()){
   //}else{
      startFibonacci(startedDatetimeFibonacciRobot);
  // }
   
}
//+------------------------------------------------------------------+

bool verifyIfHabilitedBorders(BordersOperation& borders){
   int idxCentral = (int)(borders.central);
   int idxMax = (int)(borders.max);
   int idxMin = (int)(borders.min);
   return (idxCentral != 0 && idxMax != 0 && idxMin != 0 && idxMax >= 0 && idxMin <= maxFibonacciValue);
}

BordersOperation recoverSelectedBorders(BordersOperation& borders, MqlRates& candle){
   int idxCentral = (int)(borders.central);
   int idxMax = (int)(borders.max);
   int idxMin = (int)(borders.min);
   // verificar se é necessario fazer uma nova varredura
   if(fiboValues[idxMax] >= candle.close && candle.close >= fiboValues[idxMin]){
      borders.instantiated = true;
      return borders;
   }else{
      closeBuyOrSell(0);
      selectedBordersFibonacci = toLocalizeChannel(candle.close);
      selectedBordersFibonacci.instantiated = false;
      return  selectedBordersFibonacci;
   }
}

void toBuyOrToSellFibonacciRobot(ORIENTATION orient, MqlRates& candle, bool reload){
   int idxCentral = (int)(selectedBordersFibonacci.central);
   int idxMax = (int)(selectedBordersFibonacci.max);
   int idxMin = (int)(selectedBordersFibonacci.min);
   double pointsL;
   double pointsH;
   
   Print("t");
   if(orient == UP){ 
      pointsL = (MathAbs(fiboValues[idxMin] -  fiboValues[idxCentral]) / _Point);
      pointsH = (MathAbs(fiboValues[idxCentral] -  fiboValues[idxMax]) / _Point);
   }else{
      pointsL = (MathAbs(fiboValues[idxMax] -  fiboValues[idxCentral]) / _Point);
      pointsH = (MathAbs(fiboValues[idxCentral] -  fiboValues[idxMin]) / _Point);
   }
    
   if(hasPositionOpen() == false){
     // selectedBordersFibonacci = recoverSelectedBorders(selectedBordersFibonacci, candle);
      if(verifyIfHabilitedBorders(selectedBordersFibonacci)){
            //double pointsH = MathAbs(candle.close - fiboValues[idxMax]) / _Point;
            //double pointsL = MathAbs(candle.close - fiboValues[idxCentral]) / _Point; 
            //double pointsH = MathAbs(fiboPoints[idxMax] - fiboPoints[idxCentral]);
            //double pointsL = MathAbs(fiboPoints[idxMin] - fiboPoints[idxCentral]);
            //double pointAux = (MathAbs(fiboValues[idxCentral] -  fiboValues[idxMin]) / _Point) ;
           
           if(orientationMacroFibonacci == UP){
              if(selectedBordersFibonacci.max > (maxFibonacciValue - 5) && selectedBordersFibonacci.max < maxFibonacciValue){
                  toBuyOrToSell(orient,ACTIVE_VOLUME,pointsL,pointsH);
              }else{
                  toBuyOrToSell(orient,ACTIVE_VOLUME,pointsL,pointsL);
              }
              //selectedBordersFibonacci = recoverSelectedBorders(selectedBordersFibonacci, candle);
           }else{
              if(selectedBordersFibonacci.max > 0 && selectedBordersFibonacci.max < 5){
                  toBuyOrToSell(orient,ACTIVE_VOLUME,pointsL,pointsH);
              }else{
                  toBuyOrToSell(orient,ACTIVE_VOLUME,pointsL,pointsL);
              }
              //selectedBordersFibonacci = recoverSelectedBorders(selectedBordersFibonacci, candle);
           }
           /*
          if(orient == UP){ 
             if(pointsL > pointsH){
               toBuyOrToSell(orient,ACTIVE_VOLUME,pointsL,pointsH);
            }else{
               if(reload == false){
                  selectedBordersFibonacci = toLocalizeChannel(candle.close);
                  toBuyOrToSellFibonacciRobot(orient, candle,true);
               }else{
                  toBuyOrToSell(orient,ACTIVE_VOLUME,pointsL,pointsH);
                  return;
               }
               //if(orientationMacroFibonacci != orient){
                 // toBuyOrToSell(DOWN,ACTIVE_VOLUME,pointsL, pointsL);
               //}
            } */
         /* }else{
            double pointsL = MathAbs(candle.close -  fiboValues[idxCentral]) / _Point;
            double pointsH = MathAbs(candle.close - fiboValues[idxMin]) / _Point;  
            double pointAux2 = (MathAbs(fiboValues[idxCentral] -  fiboValues[idxMax]) / _Point);
            double pointAux = (MathAbs(fiboValues[idxCentral] -  fiboValues[idxMin]) / _Point);
            
            //double pointsL = MathAbs(fiboPoints[idxMax] - fiboPoints[idxCentral]);
            //double pointsH = MathAbs(fiboPoints[idxMin] - fiboPoints[idxCentral]);
            Print("t");

               toBuyOrToSell(orient,ACTIVE_VOLUME,pointAux2,pointAux);
           if(pointsL > pointsH ){
               toBuyOrToSell(orient,ACTIVE_VOLUME,pointsL,pointsL);
            }else{
               if(reload == false){
                  selectedBordersFibonacci = toLocalizeChannel(candle.close);
                  toBuyOrToSellFibonacciRobot(orient, candle,true);
               }else{
                  toBuyOrToSell(orient,ACTIVE_VOLUME,pointsH,pointsH);
                  return;
               }
               //if(orientationMacroFibonacci != orient){
                 // toBuyOrToSell(UP,ACTIVE_VOLUME,pointsL, pointsL);
               //}
            }
         }*/
      }
   }else{
     // tradeLib.PositionModify(PositionGetTicket(0),candle.close, pointsH);
      //closeBuyOrSell(0);
   }
   selectedBordersFibonacci = recoverSelectedBorders(selectedBordersFibonacci, candle);
   
}

void startFibonacci(datetime startTime){
   ORIENTATION newOrientation = MEDIUM;
   calculateBordersFibonacci();
   
   if(!supportAndResistenceAreasDrawed){
      startSupportAndResistenceAreas();
   }else{
     int copiedPrice = CopyRates(_Symbol,_Period,0,1,candles);
     if(copiedPrice == 1){
          //se up pos[0] > pos[max]
          //se down pos[max] > pos[0]
         if(resetFibonacciValues(candles[0].close) != MEDIUM){
            Print("Resetando grafico. O valor atual ultrapassou alguma das bordas");
         }else{
           //selectedBordersFibonacci = recoverSelectedBorders(selectedBordersFibonacci, candles[0]);
           // verificar se é necessario fazer uma nova varredura
           if(selectedBordersFibonacci.instantiated == false){
              if(verifyIfHabilitedBorders(selectedBordersFibonacci)){
                  
                  //cruzou uma borda superior
                 if(crossBorderHigh(candles[0].close, selectedBordersFibonacci)){
                    toBuyOrToSellFibonacciRobot(UP,candles[0], false);
                    //newOrientation = UP;
                 }
                 //cruzou uma borda inferior
                 else if(crossBorderLow(candles[0].close, selectedBordersFibonacci)){
                     toBuyOrToSellFibonacciRobot(DOWN,candles[0], false);
                    //newOrientation = DOWN   
                 }
                 else{
                 //     selectedBordersFibonacci = recoverSelectedBorders(selectedBordersFibonacci, candles[0]);  
                 }
              }
           }
        }
     }
  }
        
   //Comment("Day: ",getActualDay(startTime));
   //return newOrientation;
}

ORIENTATION resetFibonacciValues(double actualValue){
    double aux;
    //ObjectsDeleteAll(ChartID());
    //ObjectsDeleteAll(ChartID(),0,OBJ_HLINE);
    //se up pos[0] > pos[max]
    //se down pos[max] > pos[0]
    if(orientationMacroFibonacci == UP){
      if(actualValue > fiboValues[0]){// cruzou o ponto mais alto
        generateNewLinesFibonacci = true;
        endPoint = actualValue;
        return UP;
      }else if(actualValue < fiboValues[maxFibonacciValue]){// cruzou o ponto mais baixo 
        generateNewLinesFibonacci = true;
        aux = initPoint;
        initPoint = endPoint;
        endPoint = aux;
        return DOWN;
      }
    }else if(orientationMacroFibonacci == DOWN){
      if(actualValue < fiboValues[maxFibonacciValue]){ // cruzou o ponto mais baixo
        generateNewLinesFibonacci = true;
        endPoint = actualValue;
        return DOWN;
      }else if(actualValue > fiboValues[0]){ // cruzou o ponto mais alto
        generateNewLinesFibonacci = true;
        aux = initPoint;
        initPoint = endPoint;
        endPoint = aux;
        return UP;
      }
    } 
    return MEDIUM;
}

BordersOperation toLocalizeChannel(double actualValue){
   BordersOperation bordersFibo;
   
   //if(orientationMacroFibonacci == UP){
      if(fiboValues[0] >= actualValue  && actualValue >= fiboValues[1]){
         bordersFibo.max = 0;
         bordersFibo.central = 1;
         bordersFibo.min = 2;
      }else if(fiboValues[1] >= actualValue  && actualValue >= fiboValues[2]){
         bordersFibo.max = 1;
         bordersFibo.central = 2;
         bordersFibo.min = 3;
      }else if( fiboValues[2] >= actualValue  && actualValue >= fiboValues[3]){
         bordersFibo.max = 2;
         bordersFibo.central = 3;
         bordersFibo.min = 4;
      }else if(fiboValues[3] >= actualValue && actualValue >= fiboValues[4]){
         bordersFibo.max = 3;
         bordersFibo.central = 4;
         bordersFibo.min = 5;
      }else if(actualValue <= fiboValues[4]  && actualValue >= fiboValues[5]){
         bordersFibo.max = 4;
         bordersFibo.central = 5;
         bordersFibo.min = 6;
      }else if(actualValue <= fiboValues[5]  && actualValue >= fiboValues[6]){
         bordersFibo.max = 5;
         bordersFibo.central = 6;
         bordersFibo.min = 7;
      }else if(actualValue <= fiboValues[6]  && actualValue >= fiboValues[7]){
         bordersFibo.max = 6;
         bordersFibo.central = 7;
         bordersFibo.min = 8;
      }else if(actualValue <= fiboValues[7]  && actualValue >= fiboValues[8]){
         bordersFibo.max = 7;
         bordersFibo.central = 8;
         bordersFibo.min = 9;
      }else{
         bordersFibo.max = 0;
         bordersFibo.central = 0;
         bordersFibo.min = 0;
         //resetFibonacciValues(actualValue);
      }
   //}
   /*else if(orientationMacroFibonacci == DOWN){
      if(actualValue >= fiboValues[0]  && actualValue <= fiboValues[1]){
         bordersFibo.max = 0;
         bordersFibo.central = 1;
         bordersFibo.min = 2;
      }else if(actualValue >= fiboValues[1]  && actualValue <= fiboValues[2]){
         bordersFibo.max = 1;
         bordersFibo.central = 2;
         bordersFibo.min = 3;
      }else if(actualValue >= fiboValues[2]  && actualValue <= fiboValues[3]){
         bordersFibo.max = 2;
         bordersFibo.central = 3;
         bordersFibo.min = 4;
      }else if(actualValue >= fiboValues[3]  && actualValue <= fiboValues[4]){
         bordersFibo.max = 3;
         bordersFibo.central = 4;
         bordersFibo.min = 5;
      }else if(actualValue >= fiboValues[4]  && actualValue <= fiboValues[5]){
         bordersFibo.max = 4;
         bordersFibo.central = 5;
         bordersFibo.min = 6;
      }else if(actualValue >= fiboValues[5]  && actualValue <= fiboValues[6]){
         bordersFibo.max = 5;
         bordersFibo.central = 6;
         bordersFibo.min = 7;
      }else if(actualValue >= fiboValues[6]  && actualValue <= fiboValues[7]){
         bordersFibo.max = 6;
         bordersFibo.central = 7;
         bordersFibo.min = 8;
      }else if(actualValue >= fiboValues[7]  && actualValue <= fiboValues[8]){
         bordersFibo.max = 7;
         bordersFibo.central = 8;
         bordersFibo.min = 9;
      }
   }/*/
   
   return bordersFibo;
}

bool crossBorderHigh(double actualValue, BordersOperation& borders){
   double maxBorder = fiboValues[(int)borders.max];
   double centralBorder = fiboValues[(int)borders.central];
   double pointsBorder =  centralBorder + (_Point * (pointsMaxFibonacci / 100));
   //double valueBorder = MathAbs(actualValue - actualValueBorderMax) / _Point;
   //double valueBorder = actualValueFibo;
   if(actualValue > centralBorder){
      return true;
   }
   
   return false;
}

bool crossBorderLow(double actualValue, BordersOperation& borders){
   double maxBorder = fiboValues[(int)borders.min];
   double centralBorder = fiboValues[(int)borders.central];
   double pointsBorder =  centralBorder - (_Point * (pointsMaxFibonacci / 100));
   //double valueBorder = actualValueFibo;
   if(actualValue < centralBorder ){
      return true;
   }
   
   return false;
}


void startSupportAndResistenceAreas(){
   int copiedPrice = CopyRates(_Symbol,_Period,0,1,candles);
   if(copiedPrice == 1){
      MqlRates candle = candles[0];
      if(initPoint == 0 || endPoint == 0){
         datetime actualTime = TimeCurrent();
         if(initPoint == 0){
            initPoint = candle.close;
            drawVerticalLine(actualTime, "endPoint", clrRed);
         }
         if(endPoint == 0){
           double pontuation = MathAbs(candle.close - initPoint) / _Point;
           if(pontuation > 0 && pontuation > PONTUATION_ESTIMATE){
             endPoint = candle.close;
             drawVerticalLine(actualTime, "initPoint", clrBlue);
           }
         }
      }
   
      if(initPoint != 0 && endPoint != 0){
        //double aux = initPoint;
        //initPoint = endPoint;
        //endPoint = aux;
        supportAndResistenceAreasDrawed = true;
      }else{
         supportAndResistenceAreasDrawed = false;
      }
   }
}


void calculateBordersFibonacci(){
   if(initPoint != 0 && endPoint != 0 && generateNewLinesFibonacci){
      double points = (endPoint - initPoint) / _Point;
      string nameLineFibo = "fibo", nameOvercrossFibo = "over";
      int max = maxFibonacciValue;
      
      
      // endPoint > initPoint -- Cresce pra cima
      if(points > 0){
        orientationMacroFibonacci = UP;
        for(int i = max, j = 0; i >= 0; i--, j=max-i){
            if(j < 6){
               if(j == 0){
                  //nameLineFibo = nameLineFibo + "-initPoint";
                  fiboValues[i]  = NormalizeDouble(initPoint,_Digits);
               }else if(j == 5){
                  //nameLineFibo = nameLineFibo + "-endPoint";
                  fiboValues[i]  = NormalizeDouble(endPoint,_Digits);
               }else{ 
                  fiboValues[i]  = NormalizeDouble((initPoint + (points * _Point * fiboPoints[j]) / 100), _Digits);
               }
               nameLineFibo = nameLineFibo + IntegerToString(j);
               ObjectsDeleteAll(ChartID(), nameLineFibo);
               drawHorizontalLine(fiboValues[i], 0, nameLineFibo, clrWhite);
            }else{
               nameOvercrossFibo = nameOvercrossFibo + IntegerToString(j);
               ObjectsDeleteAll(ChartID(), nameOvercrossFibo);
               fiboValues[i]  = NormalizeDouble((endPoint + ((points * _Point * fiboPoints[j]) / 100)),_Digits);
               drawHorizontalLine(fiboValues[i], 0, nameOvercrossFibo, clrWhite); 
            }
        } 
     }else{ // initPoint > endPoint  -- Cresce pra baixo
        orientationMacroFibonacci = DOWN;
        for(int i = 0; i <= max; i++){
            if(i < 6){
               if(i == 0){
                 // nameLineFibo = nameLineFibo + "-initPoint";
                  fiboValues[i]  = NormalizeDouble(initPoint,_Digits);
               }else if(i == 5){
                  //nameLineFibo = nameLineFibo + "-endPoint";
                  fiboValues[i]  = NormalizeDouble(endPoint,_Digits);
               }else{ 
                  fiboValues[i]  = NormalizeDouble((initPoint + (points * _Point * fiboPoints[i]) / 100),_Digits);
               }
               nameLineFibo = nameLineFibo + IntegerToString(i);
               ObjectsDeleteAll(ChartID(), nameLineFibo);
               drawHorizontalLine(fiboValues[i], 0, nameLineFibo, clrWhite);
            }else{
               nameOvercrossFibo = nameOvercrossFibo + IntegerToString(i);
               ObjectsDeleteAll(ChartID(), nameOvercrossFibo);
               fiboValues[i]  = NormalizeDouble((endPoint + ((points * _Point * fiboPoints[i]) / 100)),_Digits);
               drawHorizontalLine(fiboValues[i], 0, nameOvercrossFibo, clrWhite); 
            }
        }
     }
      
     int copiedPrice = CopyRates(_Symbol,_Period,0,1,candles);
     if(copiedPrice == 1){
         generateNewLinesFibonacci = false;
         selectedBordersFibonacci = toLocalizeChannel(candles[0].close);
         selectedBordersFibonacci.instantiated = false;
         Print("Fibonacci finalizado.");
     }
   }
}