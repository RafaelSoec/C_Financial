//+------------------------------------------------------------------+
//|                                                   Fibonnacci.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"
#include "ScalperRobot.mq5"

input double INIT_POINT = 0;
input double END_POINT = 0;

double initPoint = INIT_POINT;
double endPoint = END_POINT;

int countCrossBorder = 0;
int maxFibonacciValue = 9;
double pointsMaxFibonacci = 30;
double valueDealEntryPrice = 0;
bool startScalperRobotBool = false;
datetime startedDatetimeFibonacciRobot;
BordersOperation selectedBordersFibonacci;
ORIENTATION orientationMacroFibonacci = MEDIUM;
bool supportAndResistenceAreasDrawed = false;
bool generateNewLinesFibonacci = true;
bool waitNewCandleFibonacci = false;
double fiboPoints[10] = {0, 23.6, 38.2, 50, 61.8, 100, 161.8, 261.8, 432.6, 685.4};
double fiboValues[10];

double averageML[], averageMH[];
int    handleMh, handleMl, countAverage = 3;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   startedDatetimeFibonacciRobot = TimeCurrent();
     //handleMh = iMA(_Symbol,PERIOD_CURRENT,PERIOD,0,MODE_SMA,PRICE_HIGH);
     //handleMl = iMA(_Symbol,PERIOD_CURRENT,PERIOD,0,MODE_SMA,PRICE_LOW);
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
   activeFibonacciRobot(startedDatetimeFibonacciRobot);
}
//+------------------------------------------------------------------+

void activeFibonacciRobot(datetime startTime){
   if(hasNewCandle()){
     waitNewCandleFibonacci = false;
     int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
     if(copiedPrice == 2){
        valueDealEntryPrice = activeStopMovel(valueDealEntryPrice, candles[0]);
     }
   }else{
      startFibonacci(startTime);
   }
}


bool verifyIfHabilitedBorders(BordersOperation& borders){
   double idxMax = borders.max;
   double idxMin = borders.min;
   return (idxMax > 0 && idxMax < maxFibonacciValue && idxMin > 0 && idxMin < maxFibonacciValue);
}

BordersOperation recoverSelectedBorders(BordersOperation& borders, MqlRates& candle){
   if(verifyIfHabilitedBorders(borders)){
      int idxMax = (int)(borders.max);
      int idxMin = (int)(borders.min);
      
      // verificar se é necessario fazer uma nova varredura
      if(fiboValues[idxMax] >= candle.close && candle.close >= fiboValues[idxMin]){      
         borders.instantiated = true;
         return borders;
      }else{
         selectedBordersFibonacci = toLocalizeChannel(candle.close);
         selectedBordersFibonacci.instantiated = false;
         
         return  selectedBordersFibonacci;
      }
   }else{
      selectedBordersFibonacci = toLocalizeChannel(candle.close);
      return  selectedBordersFibonacci;
   }
}


void toBuyOrToSellFibonacciRobot(ORIENTATION orient, MqlRates& candle, bool reload){
   if(verifyIfHabilitedBorders(selectedBordersFibonacci)){
      int idxMax = (int)(selectedBordersFibonacci.max);
      int idxMin = (int)(selectedBordersFibonacci.min);
      double pointsL = 0;
      double pointsH = 0;
      
      if(orient == UP){ 
        int idMaxProx = idxMax < 1 ? idxMax : idxMax - 1;
        pointsL = MathAbs(candle.close - fiboValues[idxMax]) / _Point;
        pointsH = MathAbs(candle.close - fiboValues[idMaxProx]) / _Point;
      }else if(orient == DOWN){ 
        int idxMinProx = idxMin < 1 ? idxMin : idxMin - 1;
        pointsL = MathAbs(candle.close - fiboValues[idxMin]) / _Point;
        pointsH = MathAbs(candle.close - fiboValues[idxMinProx]) / _Point;
      }
   
      if(hasPositionOpen() == false){
          //pointsL = pointsL > STOP_LOSS ? STOP_LOSS : STOP_LOSS;
          //pointsH = pointsH > TAKE_PROFIT ? TAKE_PROFIT : TAKE_PROFIT;
          //pointsL = pointsL > STOP_LOSS ? STOP_LOSS : pointsL;
          //pointsL = pointsL > TAKE_PROFIT ? TAKE_PROFIT : pointsL;
         // pointsH = pointsH > TAKE_PROFIT ? TAKE_PROFIT : pointsH;
          toBuyOrToSell(orient,ACTIVE_VOLUME,pointsL,pointsH);
          valueDealEntryPrice = 0;
          waitNewCandleFibonacci = true;
      }
   
   }
}

void startFibonacci(datetime startTime){
   ORIENTATION newOrientation = MEDIUM;
   calculateBordersFibonacci();
   
   if(!supportAndResistenceAreasDrawed){
      startSupportAndResistenceAreas();
   }else{
     int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
     if(copiedPrice == 2){
          //se up pos[0] > pos[max]
          //se down pos[max] > pos[0]
         if(resetFibonacciValues(candles[1].close) != MEDIUM){
            Print("Resetando grafico. O valor atual ultrapassou alguma das bordas");
         }else{
           // verificar se é necessario fazer uma nova varredura
           if(hasPositionOpen() == false && waitNewCandleFibonacci == false){
              selectedBordersFibonacci = recoverSelectedBorders(selectedBordersFibonacci, candles[0]);
              bool passHigh = crossBorderHigh(candles[0].close, selectedBordersFibonacci);
              bool passLow = crossBorderLow(candles[0].close, selectedBordersFibonacci);
               //cruzou uma borda superior
              if(passHigh){
                 if(getOrientationPerCandles(candles[0], candles[1]) == DOWN){
                    toBuyOrToSellFibonacciRobot(DOWN,candles[0], false);
                 }
                 else{
                    toBuyOrToSellFibonacciRobot(UP,candles[0], false);
                 }
                 //newOrientation = UP;
              }
              //cruzou uma borda inferior
              else if(passLow ){
                 if(getOrientationPerCandles(candles[0], candles[1]) == UP){
                    toBuyOrToSellFibonacciRobot(UP,candles[0], false);
                 }
                 else{
                    toBuyOrToSellFibonacciRobot(DOWN,candles[0], false);
                }
                 //newOrientation = DOWN   
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
    
    // endPoint = 5
    // subida = menor valor na primeira posicao -- initPoint = 0 
    // subida = maior valor na ultima posicao  
    
    // endPoint = 5
    // descida = menor valor na ultima posicao -- initPoint
    // descida = maior valor na primeira posicao 
    if(orientationMacroFibonacci == UP){
      if(actualValue <= fiboValues[0] || actualValue >= fiboValues[maxFibonacciValue]){// cruzou o ponto mais alto
        generateNewLinesFibonacci = true;
        aux = initPoint;
        initPoint = endPoint; 
        endPoint = aux;
        //closeBuyOrSell(0);
        return DOWN;
      }else if(actualValue >= fiboValues[6]){
         //initPoint = fiboValues[1];
         initPoint = fiboValues[0];
         endPoint = fiboValues[6];
        generateNewLinesFibonacci = true;
        //closeBuyOrSell(0);
        
        return UP;
      }
    }else if(orientationMacroFibonacci == DOWN){
     // cruzou o ponto mais baixo
      if(actualValue <= fiboValues[maxFibonacciValue] || actualValue >= fiboValues[0]){
        //closeBuyOrSell(0);
        generateNewLinesFibonacci = true;
        aux = initPoint;
        initPoint = endPoint;
        endPoint = aux;
       // closeBuyOrSell(0);
        return UP;
      }else if(actualValue <= fiboValues[6]){
         //initPoint = fiboValues[1];
         initPoint = fiboValues[0];
         endPoint = fiboValues[6];
        generateNewLinesFibonacci = true;
       // closeBuyOrSell(0);
        return DOWN;
      }
    } 
    return MEDIUM;
}

BordersOperation toLocalizeChannel(double actualValue){
   BordersOperation bordersFibo;
   
   if(orientationMacroFibonacci == DOWN){
      if(fiboValues[0] >= actualValue  && actualValue >= fiboValues[1]){
         bordersFibo.max = 0;
         //bordersFibo.central = 1;
         bordersFibo.min = 1;
      }else if(fiboValues[1] >= actualValue  && actualValue >= fiboValues[2]){
         bordersFibo.max = 1;
         //bordersFibo.central = 2;
         bordersFibo.min = 2;
      }else if( fiboValues[2] >= actualValue  && actualValue >= fiboValues[3]){
         bordersFibo.max = 2;
         //bordersFibo.central = 3;
         bordersFibo.min = 3;
      }else if(fiboValues[3] >= actualValue && actualValue >= fiboValues[4]){
         bordersFibo.max = 3;
        // bordersFibo.central = 4;
         bordersFibo.min = 4;
      }else if(actualValue >= fiboValues[4]  && actualValue >= fiboValues[5]){
         bordersFibo.max = 4;
         //bordersFibo.central = 5;
         bordersFibo.min = 5;
      }else if(actualValue >= fiboValues[5]  && actualValue >= fiboValues[6]){
         bordersFibo.max = 5;
         //bordersFibo.central = 6;
         bordersFibo.min = 6;
      }else if(actualValue >= fiboValues[6]  && actualValue >= fiboValues[7]){
         bordersFibo.max = 6;
         //bordersFibo.central = 7;
         bordersFibo.min = 7;
      }else if(actualValue >= fiboValues[7]  && actualValue >= fiboValues[8]){
         bordersFibo.max = 7;
         //bordersFibo.central = 8;
         bordersFibo.min = 8;
      }else if(actualValue >= fiboValues[8]  && actualValue >= fiboValues[9]){
         bordersFibo.max = 8;
         //bordersFibo.central = 8;
         bordersFibo.min = 9;
      }
   }else if(orientationMacroFibonacci == UP){
      if(fiboValues[0] <= actualValue  && actualValue <= fiboValues[1]){
         bordersFibo.max = 1;
         //bordersFibo.central = 1;
         bordersFibo.min = 0;
      }else if( fiboValues[1] <= actualValue  && actualValue <= fiboValues[2]){
         bordersFibo.max = 2;
         //bordersFibo.central = 2;
         bordersFibo.min = 1;
      }else if( fiboValues[2] <= actualValue  && actualValue <= fiboValues[3]){
         bordersFibo.max = 3;
         //bordersFibo.central = 2;
         bordersFibo.min = 2;
      }else if(fiboValues[3] <= actualValue && actualValue <= fiboValues[4]){
         bordersFibo.max = 4;
         //bordersFibo.central = 3;
         bordersFibo.min = 3;
      }else if(actualValue <= fiboValues[4]  && actualValue <= fiboValues[5]){
         bordersFibo.max = 5;
         //bordersFibo.central = 4;
         bordersFibo.min = 4;
      }else if(actualValue <= fiboValues[5]  && actualValue <= fiboValues[6]){
         bordersFibo.max = 6;
         //bordersFibo.central = 5;
         bordersFibo.min = 5;
      }else if(actualValue <= fiboValues[6]  && actualValue <= fiboValues[7]){
         bordersFibo.max = 7;
         //bordersFibo.central = 6;
         bordersFibo.min = 6;
      }else if(actualValue <= fiboValues[7]  && actualValue <= fiboValues[8]){
         bordersFibo.max = 8;
         //bordersFibo.central = 7;
         bordersFibo.min = 7;
      }else if(actualValue <= fiboValues[8]  && actualValue <= fiboValues[9]){
         bordersFibo.max = 9;
         //bordersFibo.central = 8;
         bordersFibo.min = 8;
      }
   }
   
   return bordersFibo;
}

bool crossBorderLow(double actualValue, BordersOperation& borders){
   double centralBorder = fiboValues[(int)borders.min];
   double pointsBorder =  centralBorder - (_Point * pointsMaxFibonacci);
   //double valueBorder = actualValueFibo;
   if(actualValue < pointsBorder ){
      return true;
   }
   
   return false;
}

bool crossBorderHigh(double actualValue, BordersOperation& borders){
   double centralBorder = fiboValues[(int)borders.max];
   double pointsBorder =  centralBorder + (_Point * pointsMaxFibonacci);
   //double valueBorder = MathAbs(actualValue - actualValueBorderMax) / _Point;
   //double valueBorder = actualValueFibo;
   if(actualValue > pointsBorder){
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
       // initPoint = endPoint;
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
      
      
     for(int i = 0; i <= max; i++){
         if(i == 0){
           // nameLineFibo = nameLineFibo + "-initPoint";
            fiboValues[i]  = NormalizeDouble(initPoint,_Digits);
         }else{ 
            fiboValues[i]  = NormalizeDouble((initPoint + (points * _Point * fiboPoints[i]) / 100),_Digits);
         }
         nameLineFibo = nameLineFibo + IntegerToString(i);
         ObjectsDeleteAll(ChartID(), nameLineFibo);
         drawHorizontalLine(fiboValues[i], 0, nameLineFibo, clrWhite);
     }
     
      // endPoint > initPoint -- Cresce pra cima
     if(points > 0){
        orientationMacroFibonacci = UP;
     }else{ // initPoint > endPoint  -- Cresce pra baixo
        orientationMacroFibonacci = DOWN;
     }
     
     int copiedPrice = CopyRates(_Symbol,_Period,0,1,candles);
     if(copiedPrice == 1){
         generateNewLinesFibonacci = false;
         Print("Fibonacci finalizado.");
     }
   }
}