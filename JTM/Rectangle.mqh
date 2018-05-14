//+------------------------------------------------------------------+
//|                                                    Rectangle.mqh |
//|                                                          jawakow |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "jawakow"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Rectangle
  {
private:

public:
                     Rectangle();
                    ~Rectangle();
   void              Create();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Rectangle::Rectangle()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Rectangle::~Rectangle()
  {
  }
//+------------------------------------------------------------------+
void Rectangle::Create()
  {
   ObjectCreate("SD1"+Price,OBJ_RECTANGLE,0,time,Price,TimeCurrent(),Price);
   ObjectSet("SD1"+Price,6,Color);
   ObjectSet("SD1"+Price,OBJPROP_WIDTH,width);
   //ObjectSet("SD1"+Price,OBJPROP_TIMEFRAMES,vis);
   ObjectSet("SD1"+Price,OBJPROP_RAY_RIGHT,false);
//ObjectSetText("SD"+Price,desc+" SD");
//ObjectSetText("OpenPrice"+Price,desc+" "+NormalizeDouble(Price,Digits));
   ObjectCreate(ChartID(),"SDPrice1"+Price,OBJ_ARROW_RIGHT_PRICE,0,TimeCurrent(),Price);
   ObjectSet("SDPrice1"+Price,6,Color);
   ObjectSet("SDPrice1"+Price,OBJPROP_WIDTH,width);
   //ObjectSet("SDPrice1"+Price,OBJPROP_TIMEFRAMES,vis);
   ObjectSet("SDPrice1"+Price,OBJPROP_YDISTANCE,10);
  }

---------------------------------------------------+
//+------------------------------------------------------------------+
