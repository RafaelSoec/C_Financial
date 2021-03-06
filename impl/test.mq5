#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
//---- Plotar Etiqueta1
#property indicator_label1  "Etiqueta1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- parâmetros de entrada
input int MA_Period=21;
input int MA_Shift=0;
input ENUM_MA_METHOD MA_Method=MODE_SMA;
//--- buffers do indicador
double         Label1Buffer[];
//--- Manipulador do indicador personalizado Moving Average.mq5
int MA_handle;
//+------------------------------------------------------------------+
//| Função de inicialização do indicador customizado                 |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- mapeamento de buffers do indicador
   SetIndexBuffer(0,Label1Buffer,INDICATOR_DATA);
   ResetLastError();
   MA_handle=iCustom(NULL,0,"Examples\\Custom Moving Average",
                     MA_Period,
                     MA_Shift,
                     MA_Method,
                     PRICE_CLOSE // usando o fechamento de preços
                     );
   Print("MA_handle = ",MA_handle,"  error = ",GetLastError());
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Função de iteração do indicador customizado                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- Copiar os valores do indicador Custom Moving Average para o nosso buffer do indicador
   int copy=CopyBuffer(MA_handle,0,0,rates_total,Label1Buffer);
   Print("copy = ",copy,"    rates_total = ",rates_total);
//--- Se a nossa tentativa falhou - Reportar isto
   if(copy<=0)
      Print("Uma tentativa de obter os valores se houve falha do Custom Moving Average");
//--- valor retorno de prev_calculated para a próxima chamada
   return(rates_total);
  }