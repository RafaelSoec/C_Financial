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
double pointsMaxFibonacci = 20;
datetime startedDatetimeFibonacciRobot;
BordersOperation selectedBordersFibonacci;
ORIENTATION orientationMacroFibonacci = MEDIUM;
bool supportAndResistenceAreasDrawed = false;
bool generateNewLinesFibonacci = true;
double fiboPoints[10] = {0, 23.6, 38.2, 50, 61.8, 100, 161.8, 261.8, 432.6, 685.4};
double FiboValues[10];

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
   startFibonacci(startedDatetimeFibonacciRobot);
   
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
   if(FiboValues[idxMax] < candle.close || candle.close < FiboValues[idxMin]){
      selectedBordersFibonacci = toLocalizeChannel(candle.close);
       return  selectedBordersFibonacci;
   }
   
   return borders;
}

void toBuyOrToSellFibonacciRobot(ORIENTATION orient, MqlRates& candle, bool reload){
   if(hasPositionOpen() == false){
      selectedBordersFibonacci = recoverSelectedBorders(selectedBordersFibonacci, candle);
      int idxCentral = (int)(selectedBordersFibonacci.central);
      int idxMax = (int)(selectedBordersFibonacci.max);
      int idxMin = (int)(selectedBordersFibonacci.min);
   
      if(verifyIfHabilitedBorders(selectedBordersFibonacci)){
         if(orient == UP){ 
            double pointsH = MathAbs(candle.close - FiboValues[idxMax]) / _Point;
            double pointsL = MathAbs(candle.close - FiboValues[idxCentral]) / _Point; 
            double pointAux = (MathAbs(FiboValues[idxCentral] -  FiboValues[idxMax]) / _Point) * 0.5;
            
            if(pointsL > pointAux){
               toBuyOrToSell(UP,ACTIVE_VOLUME,pointsH,pointsL);
            }else{
               toBuyOrToSell(DOWN,ACTIVE_VOLUME,pointsL,pointsH);
            }
            
           /* if(pointsL > pointsH && pointsH > pointsMaxFibonacci){
               toBuyOrToSell(orient,ACTIVE_VOLUME,pointsL,pointsH);
            }else{
               if(reload == false){
                  selectedBordersFibonacci = toLocalizeChannel(candle.close);
                  toBuyOrToSellFibonacciRobot(orient, candle,true);
               }else{
                  toBuyOrToSell(orient,ACTIVE_VOLUME,pointsH,pointsL);
                  return;
               }
               //if(orientationMacroFibonacci != orient){
                 // toBuyOrToSell(DOWN,ACTIVE_VOLUME,pointsL, pointsL);
               //}
            } */
         }else{
            double pointAux = (MathAbs(FiboValues[idxCentral] -  FiboValues[idxMax]) / _Point) * 0.5;
            double pointsL = MathAbs(candle.close -  FiboValues[idxCentral]) / _Point;
            double pointsH = MathAbs(candle.close - FiboValues[idxMin]) / _Point;  
           
            if(pointsL > pointAux ){
               toBuyOrToSell(DOWN,ACTIVE_VOLUME,pointsH,pointsL);
            }else{
               toBuyOrToSell(UP,ACTIVE_VOLUME,pointsL,pointsH);
            }
           /* if(pointsL > pointsH && pointsH > pointsMaxFibonacci){
               toBuyOrToSell(orient,ACTIVE_VOLUME,pointsL,pointsH);
            }else{
               if(reload == false){
                  selectedBordersFibonacci = toLocalizeChannel(candle.close);
                  toBuyOrToSellFibonacciRobot(orient, candle,true);
               }else{
                  toBuyOrToSell(orient,ACTIVE_VOLUME,pointsH,pointsL);
                  return;
               }
               //if(orientationMacroFibonacci != orient){
                 // toBuyOrToSell(UP,ACTIVE_VOLUME,pointsL, pointsL);
               //}
            }*/
         }
      }
   }
}

void startFibonacci(datetime startTime){
   selectedBordersFibonacci.instantiated = false;
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
           if(verifyIfHabilitedBorders(selectedBordersFibonacci)){
               int idxCentral = (int)(selectedBordersFibonacci.central);
               int idxMax = (int)(selectedBordersFibonacci.max);
               int idxMin = (int)(selectedBordersFibonacci.min);
               // verificar se é necessario fazer uma nova varredura
               if(FiboValues[idxMax] >= candles[0].close && candles[0].close >= FiboValues[idxMin]){
                 selectedBordersFibonacci = toLocalizeChannel(candles[0].close);
               }else{
                  //cruzou uma borda superior
                 if(crossBorderHigh(candles[0].close, FiboValues[idxMax],  FiboValues[idxCentral])){
                    selectedBordersFibonacci.instantiated = true;
                    toBuyOrToSellFibonacciRobot(UP,candles[0], false);
                    //newOrientation = UP;
                 }
                 //cruzou uma borda inferior
                 else if(crossBorderLow(candles[0].close, FiboValues[idxMin],  FiboValues[idxCentral])){
                    selectedBordersFibonacci.instantiated = true;
                    toBuyOrToSellFibonacciRobot(DOWN,candles[0], false);
                    //newOrientation = DOWN   
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
      if(actualValue > FiboValues[0]){// cruzou o ponto mais alto
        generateNewLinesFibonacci = true;
        endPoint = actualValue;
        return UP;
      }else if(actualValue < FiboValues[maxFibonacciValue]){// cruzou o ponto mais baixo 
        generateNewLinesFibonacci = true;
        aux = initPoint;
        initPoint = endPoint;
        endPoint = aux;
        return DOWN;
      }
    }else if(orientationMacroFibonacci == DOWN){
      if(actualValue < FiboValues[maxFibonacciValue]){ // cruzou o ponto mais baixo
        generateNewLinesFibonacci = true;
        endPoint = actualValue;
        return DOWN;
      }else if(actualValue > FiboValues[0]){ // cruzou o ponto mais alto
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
   
   if(orientationMacroFibonacci == UP){
      if(actualValue <= FiboValues[1]  && actualValue >= FiboValues[2]){
         bordersFibo.max = 0;
         bordersFibo.central = 1;
         bordersFibo.min = 2;
      }else if(actualValue <= FiboValues[2]  && actualValue >= FiboValues[3]){
         bordersFibo.max = 1;
         bordersFibo.central = 2;
         bordersFibo.min = 3;
      }else if(actualValue <= FiboValues[3]  && actualValue >= FiboValues[4]){
         bordersFibo.max = 2;
         bordersFibo.central = 3;
         bordersFibo.min = 4;
      }else if(actualValue <= FiboValues[4]  && actualValue >= FiboValues[5]){
         bordersFibo.max = 3;
         bordersFibo.central = 4;
         bordersFibo.min = 5;
      }else if(actualValue <= FiboValues[5]  && actualValue >= FiboValues[6]){
         bordersFibo.max = 4;
         bordersFibo.central = 5;
         bordersFibo.min = 6;
      }else if(actualValue <= FiboValues[6]  && actualValue >= FiboValues[7]){
         bordersFibo.max = 5;
         bordersFibo.central = 6;
         bordersFibo.min = 7;
      }else if(actualValue <= FiboValues[7]  && actualValue >= FiboValues[8]){
         bordersFibo.max = 6;
         bordersFibo.central = 7;
         bordersFibo.min = 8;
      }else if(actualValue <= FiboValues[8]  && actualValue >= FiboValues[9]){
         bordersFibo.max = 7;
         bordersFibo.central = 8;
         bordersFibo.min = 9;
      }
   }else if(orientationMacroFibonacci == DOWN){
      if(actualValue >= FiboValues[0]  && actualValue <= FiboValues[1]){
         bordersFibo.max = 0;
         bordersFibo.central = 1;
         bordersFibo.min = 2;
      }else if(actualValue >= FiboValues[1]  && actualValue <= FiboValues[2]){
         bordersFibo.max = 1;
         bordersFibo.central = 2;
         bordersFibo.min = 3;
      }else if(actualValue >= FiboValues[2]  && actualValue <= FiboValues[3]){
         bordersFibo.max = 2;
         bordersFibo.central = 3;
         bordersFibo.min = 4;
      }else if(actualValue >= FiboValues[3]  && actualValue <= FiboValues[4]){
         bordersFibo.max = 3;
         bordersFibo.central = 4;
         bordersFibo.min = 5;
      }else if(actualValue >= FiboValues[4]  && actualValue <= FiboValues[5]){
         bordersFibo.max = 4;
         bordersFibo.central = 5;
         bordersFibo.min = 6;
      }else if(actualValue >= FiboValues[5]  && actualValue <= FiboValues[6]){
         bordersFibo.max = 5;
         bordersFibo.central = 6;
         bordersFibo.min = 7;
      }else if(actualValue >= FiboValues[6]  && actualValue <= FiboValues[7]){
         bordersFibo.max = 6;
         bordersFibo.central = 7;
         bordersFibo.min = 8;
      }else if(actualValue >= FiboValues[7]  && actualValue <= FiboValues[8]){
         bordersFibo.max = 7;
         bordersFibo.central = 8;
         bordersFibo.min = 9;
      }
   }
   
   return bordersFibo;
}

bool crossBorderHigh(double actualValue, double actualValueBorderMax, double actualValuePrevBorder){
   double pointsBorder = (MathAbs(actualValueBorderMax - actualValuePrevBorder) / _Point) * (pointsMaxFibonacci / 100);
   double valueBorder = (actualValue - actualValueBorderMax) / _Point;
   //double valueBorder = actualValueFibo;
   if(valueBorder > pointsBorder){
      return true;
   }
   
   return false;
}

bool crossBorderLow(double actualValue, double actualValueBorderMin, double actualValuePrevBorder){
   double pointsBorder = (MathAbs(actualValueBorderMin - actualValuePrevBorder) / _Point)  * (pointsMaxFibonacci / 100);
   double valueBorder = (actualValueBorderMin - actualValue) / _Point;
   //double valueBorder = actualValueFibo;
   if(valueBorder > pointsBorder){
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
            //drawHorizontalLine(initPoint, actualTime, "endPoint", clrRed);
         }
         if(endPoint == 0){
           double pontuation = MathAbs(candle.close - initPoint) / _Point;
           if(pontuation > 0 && pontuation > PONTUATION_ESTIMATE){
             endPoint = candle.close;
             //drawHorizontalLine(endPoint, actualTime, "initPoint", clrRed);
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
                  FiboValues[i]  = NormalizeDouble(initPoint,_Digits);
               }else if(j == 5){
                  //nameLineFibo = nameLineFibo + "-endPoint";
                  FiboValues[i]  = NormalizeDouble(endPoint,_Digits);
               }else{ 
                  FiboValues[i]  = NormalizeDouble((initPoint + (points * _Point * fiboPoints[j]) / 100), _Digits);
               }
               nameLineFibo = nameLineFibo + IntegerToString(j);
               ObjectsDeleteAll(ChartID(), nameLineFibo);
               drawHorizontalLine(FiboValues[i], 0, nameLineFibo, clrWhite);
            }else{
               nameOvercrossFibo = nameOvercrossFibo + IntegerToString(j);
               ObjectsDeleteAll(ChartID(), nameOvercrossFibo);
               FiboValues[i]  = NormalizeDouble((endPoint + ((points * _Point * fiboPoints[j]) / 100)),_Digits);
               drawHorizontalLine(FiboValues[i], 0, nameOvercrossFibo, clrWhite); 
            }
        } 
     }else{ // initPoint > endPoint  -- Cresce pra baixo
        orientationMacroFibonacci = DOWN;
        for(int i = 0; i <= max; i++){
            if(i < 6){
               if(i == 0){
                 // nameLineFibo = nameLineFibo + "-initPoint";
                  FiboValues[i]  = NormalizeDouble(initPoint,_Digits);
               }else if(i == 5){
                  //nameLineFibo = nameLineFibo + "-endPoint";
                  FiboValues[i]  = NormalizeDouble(endPoint,_Digits);
               }else{ 
                  FiboValues[i]  = NormalizeDouble((initPoint + (points * _Point * fiboPoints[i]) / 100),_Digits);
               }
               nameLineFibo = nameLineFibo + IntegerToString(i);
               ObjectsDeleteAll(ChartID(), nameLineFibo);
               drawHorizontalLine(FiboValues[i], 0, nameLineFibo, clrWhite);
            }else{
               nameOvercrossFibo = nameOvercrossFibo + IntegerToString(i);
               ObjectsDeleteAll(ChartID(), nameOvercrossFibo);
               FiboValues[i]  = NormalizeDouble((endPoint + ((points * _Point * fiboPoints[i]) / 100)),_Digits);
               drawHorizontalLine(FiboValues[i], 0, nameOvercrossFibo, clrWhite); 
            }
        }
     }
      
     generateNewLinesFibonacci = false;
     int copiedPrice = CopyRates(_Symbol,_Period,0,1,candles);
     if(copiedPrice == 1){
         selectedBordersFibonacci = toLocalizeChannel(candles[0].close);
         Print("Fibonacci finalizado.");
     }
   }
}