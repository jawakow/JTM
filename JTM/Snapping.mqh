//+------------------------------------------------------------------+
//|                                                     Snapping.mqh |
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
class Snapping
  {
private:

public:

                     Snapping();
                    ~Snapping();
   double            getBarHighLowByMousePos(int x,int y);
   datetime          getTimeByByMousePos(int x,int y);
   void              snapSelectedHLine(double price);
   void              setLinePipsDist(string name, double entryPrice,double targetPrice);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Snapping::Snapping()
  {
   datetime dt=0;
   double   price =0;
   int      window=0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Snapping::~Snapping()
  {
  }
//+------------------------------------------------------------------+
double Snapping::getBarHighLowByMousePos(int x,int y)
  {
//--- Prepare variables
   double SZ,DZ;
//int vis;
//string space,desc;
   double Zone=Close[1];
//int      x     =(int)lparam;
//int      y     =(int)dparam;
   datetime dt    =0;
   double   price =0;
   int      window=0;
//--- Convert the X and Y coordinates in terms of date/time
   if(ChartXYToTimePrice(0,x,y,window,dt,price))
     {
      int SFPBar=iBarShift(Symbol(),0,dt,true);
      if ( SFPBar == -1 ) return(price); 
      if(Close[SFPBar]>Open[SFPBar])
        {
         SZ = Open[SFPBar];
         DZ = Close[SFPBar];
        }
      else
        {
         DZ = Open[SFPBar];
         SZ = Close[SFPBar];
        }
      //SetVis();
      Zone=price;
      if(price>High[SFPBar]) Zone=High[SFPBar];
      if(price<High[SFPBar] && price>DZ) Zone=DZ;
      if(price<Low[SFPBar]) Zone=Low[SFPBar];
      if(price>Low[SFPBar] && price<SZ) Zone=SZ;

     }
   return(Zone);
  }
//+------------------------------------------------------------------+
datetime Snapping::getTimeByByMousePos(int x,int y)
  {
   datetime dt    =0;
   double   price =0;
   int      window=0;
   if(ChartXYToTimePrice(0,x,y,window,dt,price)) return(dt);
   else return(TimeCurrent());
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Snapping::snapSelectedHLine(double price)
  {

     {
      string name1;
      int obj_total=ObjectsTotal();
      for(int i=0;i<=obj_total;i++)
        {
         name1=ObjectName(i);
         if(ObjectType(name1)==OBJ_HLINE && ObjectGetInteger(0,name1,OBJPROP_SELECTED,0)==True)
           {
            ObjectSet(name1,1,price);
            ObjectSetInteger(0,name1,OBJPROP_SELECTED,False);
           }

        }
      ChartRedraw();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Snapping::setLinePipsDist(string name, double entryPrice,double targetPrice)
  {
   //Print("test");
   int distance=MathAbs(entryPrice-targetPrice)/Point;
  

   ObjectSetText(name,DoubleToString(distance,0)+" ticks");
  }
//+------------------------------------------------------------------+
