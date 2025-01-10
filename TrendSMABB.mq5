
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property description "Cazador de tendencias con una media movil simple."
#property link      "https://www.mql5.com"
#property version   "1.00"


//+------------------------------------------------------------------+
//| Inputs y variables                                               |
//+------------------------------------------------------------------+


sinput group "EA Ajustes Generales"
input ulong MagicNumber = 101;


sinput group "EA Ajustes Media Movil"
input int PeriodMA = 30;
input ENUM_MA_METHOD MethodMA = MODE_SMA;
input int ShiftMA = 0;
input ENUM_APPLIED_PRICE PriceMA = PRICE_CLOSE;

sinput group "EA Gestion de Riesgo"
input double FixedVolume = 0.1;

sinput group "EA Gestion Posiciones"
input ushort FixedPointSL = 0;      //SL FIJO
input ushort FixedPointMASL = 0;    //SL MA
input ushort FixedPointTP = 0;      //TP FIJO
input ushort FixedPointBE = 0;      //BE POINTS
input ushort FixedPointTSL = 0;     //TRAILING SL POINTS


datetime glTiempoAperturaBarra;
int manejadorMA;
int manejadorBB;

//+------------------------------------------------------------------+
//| Procesadores de eventos                                          |
//+------------------------------------------------------------------+


int OnInit() {

   glTiempoAperturaBarra = D'1971.01.01 00:00';
   
   
   manejadorMA = MA_init(PeriodMA, ShiftMA, MethodMA, PriceMA);
   if(manejadorMA == -1){
     Print("No se pudo inicializar la MEDIA MOVIL");
     return (INIT_FAILED);
   }
   
   manejadorBB = BB_init(20, 0,2,PRICE_CLOSE);
   if(manejadorBB == -1){
     Print("No se pudo inicializar BOLLINGER");
     return (INIT_FAILED);
   }
   
   Print("===== INICIO SMA TREND =====");
   return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason) {
      Print("Asesor Detenido.");
} 
  

void OnTick() {
  
  // ===== Control Nueva Barra ===== //
  
  bool nuevaBarra = false;
  
  //Comprobar nueva barra
  if(glTiempoAperturaBarra != iTime(_Symbol, PERIOD_CURRENT, 0)) {
      nuevaBarra = true; 
      glTiempoAperturaBarra = iTime(_Symbol, PERIOD_CURRENT, 0);
  }
  
  if(nuevaBarra == true){
      Print("Nueva Barra Detectada.");
      
      
      // ========== PRECIO DE INDICADORES ========== //
      
      //Print("Precio cierre vela 1: ", Cierre(1));    
      //Print("Cierre Normalizado: ", Normalizar(Cierre(1)));
      
      //Print("Precio apertura vela 1: ", Apertura(1));    
      // Print("Apertura Normalizada: ", Normalizar(Apertura(1)));
      
      
      double Cierre1 = Normalizar(Cierre(1));
      double Apertura1 = Normalizar(Apertura(1));
      
      double ma1 = ma(manejadorMA, 1);
      Print("Precio media Movil 1: ", ma1);
      
      
      // ======== BB TEST ========= //
      
      double bbMid = BB(manejadorBB, 1, 0);
      double bbUp = BB(manejadorBB, 1, 1);
      double bbLow = BB(manejadorBB, 1, 2);
      
      Print("Precio de la banda Media de bollinger: ", bbMid);
      Print("Precio de la banda Alta de bollinger: ", bbUp);
      Print("Precio de la banda Baja de bollinger: ", bbLow);
      
      
      
      string orden = CruceDeMedia(Apertura1, Cierre1, ma1);
      if(orden == "Compra")
      {
         Print(" ===== COMPRAMOS ===== ");
         
         string valores = "";
         StringConcatenate(valores, "Precio Apertura: ", Apertura1, " Precio Cierre: ", Cierre1, " Precio de SMA: ", ma1);
         Print("Valores vela anterior: ", valores);
         
      }if(orden == "Venta")
      {
         Print(" ===== Vendemos ===== ");
         
         string valores = "";
         StringConcatenate(valores, "Precio Apertura: ", Apertura1, " Precio Cierre: ", Cierre1, " Precio de SMA: ", ma1);
         Print("Valores vela anterior: ", valores);
         
      }
      
      
      
  }
  
  
   
}
//+------------------------------------------------------------------+


//  -------------- Funciones Precio -------------- //

double Cierre(int CustomShift){

   double cierre = Normalizar( iClose(_Symbol, PERIOD_CURRENT, CustomShift) );
   return cierre; 
}

double Apertura(int CustomShift){

   double apertura = Normalizar ( iOpen(_Symbol, PERIOD_CURRENT, CustomShift) );
   return apertura;

}

double Normalizar(double numero){

   return NormalizeDouble(numero, _Digits);

}


double CloseEmpirico (int Shift){
   
   MqlRates barra[];                                  //Crea un objeto array del tipo estructura MqlRates.
   ArraySetAsSeries(barra, true);                     //Configura el array como uno en serie, para asi poder rellenarlo del 0 hacia atras de forma ascendente.
   CopyRates(_Symbol, PERIOD_CURRENT, 0, 3, barra);   //Copia datos del precio de la barra 0, 1 y 2 porque le pusimos que copie solo 3 valores.
   
   return barra[Shift].close;                         //Retorna el cierre de la vela del array, correspondiente al shift colocado cono paramtatro.
   
}

double OpenEmpirico (int Shift){
   
   MqlRates barra[];                                  //Crea un objeto array del tipo estructura MqlRates.
   ArraySetAsSeries(barra, true);                     //Configura el array como uno en serie, para asi poder rellenarlo del 0 hacia atras de forma ascendente.
   CopyRates(_Symbol, PERIOD_CURRENT, 0, 3, barra);   //Copia datos del precio de la barra 0, 1 y 2 porque le pusimos que copie solo 3 valores.
   
   return barra[Shift].open;                         //Retorna el cierre de la vela del array, correspondiente al shift colocado cono paramtatro.
   
}






//  -------------- Funciones Media Movil -------------- //

int MA_init(int periodo, int shift, ENUM_MA_METHOD metodoMa, ENUM_APPLIED_PRICE precioMA){

   //Reset _LastError a cero, de esta forma si obtenemos un error al inicializar la media movil, sabremos a que se debe.
   ResetLastError();
   
   //Handler o manejador es un identificador unico para el indicador, usado para recibir datos, eliminarlo, etc.
   int Manejador = iMA(_Symbol, PERIOD_CURRENT, periodo, shift, metodoMa, precioMA);
   
   if(Manejador == INVALID_HANDLE){
   
      Print("Ha habido un error creando el indicador de la media movil: ", GetLastError());
      return -1;
      
   }
   
   Print("Manejador MA inicializado con exito.");
   return Manejador;
}

double ma (int manejador, int shift){

   ResetLastError();
   
   //Creamos un array que llenaremos con los precios del indicador.
   double ma[];
   ArraySetAsSeries(ma, true);
   bool resultado = CopyBuffer(manejador, 0, 0, 10, ma);
   if(resultado == false) {
      Print("Error al copiar datos: ", GetLastError());}
      
   //Preguntar por el valor almacenado en Shift:
   double valorMA = ma[shift];
   return Normalizar(valorMA);

}


//  -------------- Funciones BB -------------- //

int BB_init(int periodoBB, int shiftBB, double devBB,ENUM_APPLIED_PRICE precioBB){

   //Reset _LastError a cero, de esta forma si obtenemos un error al inicializar las bandas de bollinger, sabremos a que se debe.
   ResetLastError();
   
   //Handler o manejador es un identificador unico para el indicador, usado para recibir datos, eliminarlo, etc.
   int Manejador = iBands(_Symbol, PERIOD_CURRENT, periodoBB, shiftBB, devBB, precioBB);
   
   if(Manejador == INVALID_HANDLE){
   
      Print("Ha habido un error creando las bandas de bollinger: ", GetLastError());
      return -1;
      
   }
   
   Print("Manejador BOLLINGER inicializado con exito.");
   return Manejador;
}

double BB (int manejador, int shift, int buffer){

   ResetLastError();
   
   //Creamos un array que llenaremos con los precios del indicador.
   double BB[];
   ArraySetAsSeries(BB, true);
   bool resultado = CopyBuffer(manejador, buffer, 0, 10, BB);
   if(resultado == false) {
      Print("Error al copiar datos: ", GetLastError());}
      
   //Preguntar por el valor almacenado en Shift:
   double valorBB = BB[shift];
   return Normalizar(valorBB);

}


// =============== FUNCIONES SENALES ================= //


string CruceDeMedia(double open, double close, double pricema){

    if (open < pricema && close >= pricema){
      return "Compra";
    } else if( open > pricema && close <= pricema){
      return "Venta";        
    }
    
    return NULL;
   
}