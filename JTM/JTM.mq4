//+------------------------------------------------------------------+
//|                                                          JTM.mq4 |
//|                                                          jawakow |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "jawakow"
#property link      ""
#property version   "1.00"
#property strict

#include <Controls\Button.mqh>
#include <Controls\CheckBox.mqh>
#include <Watchlist.mqh>
#include <MultiCharts.mqh>
#include "Snapping.mqh"
//#include "Rectangle.mqh"
CCheckBox sdCheckBox;
CCheckBox snapCheckBox;
CCheckBox ppzCheckBox;
CCheckBox showPanel;
CButton multiChartsButton;
CButton addSpread;
Snapping snapping;
datetime NewBarTime;
double Color;
int vis,width,style;
string space,desc;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
double Bal=0;
double Balance;
int Risk;
double tradeVolume,cR,spread;
double StopLossPoints;
double SFP_Stop=0;
double Price;
int magic;
double SLPrice,spr,Margin,Units;
double Level,Entry,TickSize,OpenOrderRisk,TPPrice,MinStopValue;
bool POO=false;
double LotStep;
double LotMM;
int ticket;
int err,LimitTarget;
extern bool FixedTradeLoss=false;
bool safeTemplate=true;
int xMousePos;
int yMousePos;
extern double limitATM=30;
extern double stopATM=100;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
//if(ChartID()!=ChartFirst()) ExpertRemove();
//ChartApplyTemplate(0,"JTM "+Symbol());
   EventSetTimer(1);
   ChartSetInteger(ChartID(),CHART_EVENT_MOUSE_MOVE,true);
   ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_CREATE,true);
   spread=(MarketInfo(Symbol(),MODE_SPREAD))*Point;
//Print(Period());
//RedrawLines();

   shiftSD();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   destroy();
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(isEntryLevelsExists()) Main();
   if(NewBar()) shiftSD();
   if(POO)
     {
      Pending();
      POO=false;
      ButRelease("POO");
     }

  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   if(!ChartGetInteger(0,CHART_BRING_TO_TOP)) destroy();
//if(ChartGetInteger(0,CHART_BRING_TO_TOP)) createMenu();
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   if(id==CHARTEVENT_MOUSE_MOVE)
     {
      checkSD();
      snapping.setLinePipsDist("TP",Entry,TPPrice);
      snapping.setLinePipsDist("InitStop",Entry,SLPrice);
      xMousePos=(int)lparam;
      yMousePos=(int)dparam;
      //Print(xMousePos);
      //Print("test");
     }

   if(id==CHARTEVENT_KEYDOWN)
     {
      Print(lparam);
      //destroy();
      if(lparam==82) createMenu();
      if(lparam==83)
        {
         snapping.snapSelectedHLine(snapping.getBarHighLowByMousePos(xMousePos,yMousePos));

        }

/*
      if(lparam==190 )
        {destroy(); switchSymbol(); }
      if(lparam==188)
        {destroy(); SwitchBackward();}
      */

      if(lparam==76)
        {
         //Print(snapping.getBarHighLowByMousePos(xMousePos, yMousePos));
         Print(Point);
         Entry=snapping.getBarHighLowByMousePos(xMousePos,yMousePos);

         if(Bid>Entry)
           {
            SLPrice=Entry-(stopATM*Point);
            TPPrice=Entry+(limitATM*Point);
           }
         if(Bid<Entry)
           {
            SLPrice=Entry+(stopATM*Point);
            TPPrice=Entry-(limitATM*Point);
           }
         Pending();

        }
      if(lparam==72) destroy();
      if(lparam==68)
        {
         destroy();
         saveTemplate();
         ChartSetSymbolPeriod(0,NULL,PERIOD_D1);
         applyTemplate();
         safeTemplate=false;
        }
      if(lparam==87)
        {
         destroy();
         saveTemplate();
         ChartSetSymbolPeriod(0,NULL,PERIOD_W1);
         applyTemplate();
         safeTemplate=true;
        }
      if(lparam==77)
        {
         destroy();
         saveTemplate();
         ChartSetSymbolPeriod(0,NULL,PERIOD_MN1);
         applyTemplate();
         safeTemplate=true;
        }
      if(lparam==67) ObjectsDeleteAll();
      if(lparam==65)
        {
         //applyDarkTemplate();
         applyTemplate();
         safeTemplate=false;
        }
      if(lparam==83)
        {
         applyDarkTemplate();
         safeTemplate=true;
         //applyTemplate();
        }
     }

   if(id==CHARTEVENT_OBJECT_CREATE && ObjectGetInteger(0,sparam,OBJPROP_TYPE)==OBJ_TREND)
     {
      SetVis();
      TF();
      ObjectSet(sparam,OBJPROP_TIMEFRAMES,vis);
      ObjectSet(sparam,OBJPROP_COLOR,Color);
      ObjectSet(sparam,OBJPROP_WIDTH,width);
      //shiftSD();
     }
   if(id==CHARTEVENT_OBJECT_CREATE && ObjectGetInteger(0,sparam,OBJPROP_TYPE)==OBJ_RECTANGLE)
     {
      SetVis();
      TF();
      ObjectSet(sparam,OBJPROP_TIMEFRAMES,vis);
      ObjectSet(sparam,OBJPROP_COLOR,Color);
      ObjectSet(sparam,OBJPROP_WIDTH,width);
      ObjectSet(sparam,OBJPROP_STYLE,style);
      //createPriceLabel(sparam);
      shiftSD();
     }
   if(id==CHARTEVENT_OBJECT_DRAG && ObjectGetInteger(0,sparam,OBJPROP_TYPE)==OBJ_RECTANGLE)
     {

      SetVis();
      TF();
      movePriceLabels(sparam);

     }

   if(id==CHARTEVENT_OBJECT_DRAG && ObjectGetInteger(0,sparam,OBJPROP_TYPE)==OBJ_TREND) checkSD();
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="multiChartsButton") multiCharts();
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="addSpread") addSpreadToEntry();
   if(id==CHARTEVENT_CLICK && dparam>30 && sdCheckBox.Checked())
     {

      double SZ,DZ;
      double Zone;
      int      x     =(int)lparam;
      int      y     =(int)dparam;
      datetime dt    =0;
      double   price =0;
      int      window=0;
      //--- Convert the X and Y coordinates in terms of date/time
      if(ChartXYToTimePrice(0,x,y,window,dt,price))
        {
         int SFPBar=iBarShift(Symbol(),0,dt,false);
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
      drawSD(Zone,dt);

     }
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      Main();
      if(ObjectGetInteger(0,sparam,OBJPROP_TYPE,0)==OBJ_BUTTON)
        {
         ButtonColorPressed(sparam);
         ButtonExe(sparam);
         if(ObjectGetInteger(0,sparam,OBJPROP_BGCOLOR,0)==Red) ButRelease(sparam);
        }

     }
   if(snapCheckBox.Checked() && id==CHARTEVENT_MOUSE_MOVE)
     {
      //--- Prepare variables
      double Color,SZ,DZ;
      int vis;
      string space,desc;
      double Zone;
      int      x     =(int)lparam;
      int      y     =(int)dparam;
      datetime dt    =0;
      double   price =0;
      int      window=0;
      //--- Convert the X and Y coordinates in terms of date/time
      if(ChartXYToTimePrice(0,x,y,window,dt,price))
        {
         int SFPBar=iBarShift(Symbol(),0,dt,false);

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
         if(price>High[SFPBar]) Zone=High[SFPBar];
         if(price<High[SFPBar] && price>DZ) Zone=DZ;
         if(price<Low[SFPBar]) Zone=Low[SFPBar];
         if(price>Low[SFPBar] && price<SZ) Zone=SZ;

         if(ObjectGetInteger(0,"OpenPrice",OBJPROP_SELECTED,0)==true) ObjectSet("OpenPrice",1,Zone);
         if(ObjectGetInteger(0,"TP",OBJPROP_SELECTED,0)==true) ObjectSet("TP",1,Zone);
         if(ObjectGetInteger(0,"InitStop",OBJPROP_SELECTED,0)==true) ObjectSet("InitStop",1,Zone);

        }
     }

   if(id==CHARTEVENT_CLICK && dparam>30 && ppzCheckBox.Checked())
     {

      double SZ,DZ;
      double Zone;
      int      x     =(int)lparam;
      int      y     =(int)dparam;
      datetime dt    =0;
      double   price =0;
      int      window=0;
      //--- Convert the X and Y coordinates in terms of date/time
      if(ChartXYToTimePrice(0,x,y,window,dt,price))
        {
         int SFPBar=iBarShift(Symbol(),0,dt,false);
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
      drawPPZ(Zone);

     }
   if(id==CHARTEVENT_MOUSE_MOVE & snapCheckBox.Checked())

     {

      int obj_total=ObjectsTotal();
      string name;
      for(int i=0;i<obj_total;i++)
        {
         name=ObjectName(i);
         double SZ,DZ;
         double Zone;
         int      x     =(int)lparam;
         int      y     =(int)dparam;
         datetime dt    =0;
         double   price =0;
         int      window=0;
         //--- Convert the X and Y coordinates in terms of date/time
         if(ChartXYToTimePrice(0,x,y,window,dt,price))
           {
            int SFPBar=iBarShift(Symbol(),0,dt,false);
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

            //if(ObjectGetInteger(0,name,OBJPROP_SELECTED,0)==true && StringFind(name,"PPZ",0)!=-1) ObjectSet(name,1,Zone);
            if(ObjectGetInteger(0,name,OBJPROP_SELECTED,0)==true && ObjectGetInteger(0,name,OBJPROP_TYPE,0) ==OBJ_HLINE) ObjectSet(name,1,Zone);

           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void Main()
  {
   TickSize=MarketInfo(Symbol(),MODE_TICKSIZE);
   SLPrice = MathRound(ObjectGet("InitStop",1)/TickSize)*TickSize;
   TPPrice = MathRound(ObjectGet("TP",1)/TickSize)*TickSize;
   Entry=MathRound(ObjectGet("OpenPrice",1)/TickSize)*TickSize;
   Level=Entry;
   OpenOrderRisk=StringToDouble(ObjectGetString(ChartID(),"RiskSet",OBJPROP_TEXT,0));
   string command=ObjectGetString(ChartID(),"RiskSet",OBJPROP_TEXT,0);
   spread=(MarketInfo(Symbol(),MODE_SPREAD))*Point;
   spr=(MarketInfo(Symbol(),MODE_SPREAD));
   SetVis();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(SLPrice>Bid)
     {
      if(Level<=0)
        {
         StopLossPoints=(SLPrice-Bid)/TickSize;
         cR=(Bid-TPPrice)/(SLPrice-Bid);
         LimitTarget=DoubleToStr(MathAbs(Bid-TPPrice)/TickSize,0);
        }
      else
        {
         StopLossPoints=(SLPrice-Level)/TickSize;
         cR=(Level-TPPrice)/(SLPrice-Level);
         LimitTarget=DoubleToStr(MathAbs(Level-TPPrice)/TickSize,0);
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   else
     {
      if(Level<=0)
        {
         StopLossPoints=(Ask-SLPrice)/TickSize;
         cR=(TPPrice-Ask)/(Ask-SLPrice);
         LimitTarget=DoubleToStr(MathAbs(Ask-TPPrice)/TickSize,0);
        }
      else
        {
         StopLossPoints=(Level-SLPrice)/TickSize;
         cR=(TPPrice-Level)/(Level-SLPrice);
         LimitTarget=DoubleToStr(MathAbs(Level-TPPrice)/TickSize,0);
        }
     }
   if(StopLossPoints<0) StopLossPoints=-StopLossPoints;
   if(Bal==0) Balance=AccountBalance()+AccountCredit();
   if(Bal!=0) Balance=Bal;
//Print(MarketInfo(Symbol(),MODE_TICKVALUE));
   tradeVolume=(Balance*OpenOrderRisk/100)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));
   if(FixedTradeLoss) tradeVolume=(OpenOrderRisk)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));;
   LotStep=MarketInfo(Symbol(),MODE_LOTSTEP);
   LotMM=MathFloor(tradeVolume/LotStep)*LotStep;
   if(LotMM<MarketInfo(Symbol(),MODE_MINLOT)) LotMM=MarketInfo(Symbol(),MODE_MINLOT);
   Margin=MarketInfo(Symbol(),MODE_MARGINREQUIRED)*LotMM;

   MinStopValue=(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE))*LotMM;

/*
   if (!showPanel.Checked()) 
   {
    LotMM=0;
    MinStopValue=0;
    Margin=0;
    
   }
   */

   ObjectSetText("Volume","Volume "+DoubleToStr(LotMM,2)+", Stop "+DoubleToStr(MinStopValue,1),10,"Times New Roman",White);
   ObjectSetText("Margin","Margin "+DoubleToStr(Margin,1),10,"Times New Roman",White);
   ObjectSetText("RR","RR "+DoubleToStr(cR,2),10,"Times New Roman",White);
   ObjectSetText("AC","Spread "+DoubleToString(spr,0),10,"Times New Roman",White);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ButtonCreate(string ButName,string ButDesc,int Xdis,int Ydis,color col)
  {
   ObjectCreate(0,ButName,OBJ_BUTTON,0,0,0);
   ObjectSetString(0,ButName,OBJPROP_TEXT,ButDesc);
   ObjectSetInteger(0,ButName,OBJPROP_XDISTANCE,Xdis);
   ObjectSetInteger(0,ButName,OBJPROP_YDISTANCE,Ydis);
   ObjectSetInteger(0,ButName,OBJPROP_XSIZE,45);
   ObjectSetInteger(0,ButName,OBJPROP_YSIZE,20);
   ObjectSetInteger(0,ButName,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,ButName,OBJPROP_BGCOLOR,col);
   ObjectSetInteger(0,ButName,OBJPROP_COLOR,White);
   ObjectSetInteger(0,ButName,OBJPROP_BORDER_COLOR,White);
   ObjectSetInteger(0,ButName,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,ButName,OBJPROP_FONTSIZE,6);

  }
//+------------------------------------------------------------------+

void ButtonColorPressed(string ButName)
  {
   if(ObjectGet(ButName,OBJPROP_STATE))
     {
      //ObjectSetInteger(0,ButName,OBJPROP_BGCOLOR,Blue);
      //ButRelease(ButName);
     }

//else ObjectSetInteger(0,ButName,OBJPROP_BGCOLOR,Red);
  }
//+------------------------------------------------------------------+

void ButRelease(string ButName)
  {

   ObjectSetInteger(0,ButName,OBJPROP_STATE,false);
//ObjectSetInteger(0,ButName,OBJPROP_BGCOLOR,Red);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ButtonExe(string ButName)
  {
   if(ButName=="Trade") Trade();
   if(ButName=="Redraw") RedrawLines();
   if(ButName=="Pending") Pending();
   if(ButName=="POO") POO=true;
   if(ButName=="SFP_Stop") SFP_Stop();
   if(ButName=="Hide") DeleteLines();
//if(ButName=="Snap") Snap();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetObjectCoordinates(string ButName)
  {
   Print("X ",ObjectGetInteger(0,ButName,OBJPROP_XDISTANCE)," Y ",ObjectGetInteger(0,ButName,OBJPROP_YDISTANCE));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ATRPeriod()
  {
   if(Period() == 5) return(12);
   if(Period() == 60) return(24);
   if(Period() == 240) return(30);
   if(Period() == 1440) return(20);
   if(Period() == 10080) return(52);
   else return(14);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Pending()
  {
   if(IsTradeAllowed())
     {

      RefreshRates();

      // buy limit
      if(Entry!=0 && Bid>Entry && SLPrice<Entry)
        {

         StopLossPoints=(Entry-SLPrice)/TickSize;
         tradeVolume=(AccountBalance()*OpenOrderRisk/100)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));
         if(FixedTradeLoss) tradeVolume=(OpenOrderRisk)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));;

         LotStep=MarketInfo(Symbol(),MODE_LOTSTEP);
         LotMM=MathFloor(tradeVolume/LotStep)*LotStep;
         if(LotMM<MarketInfo(Symbol(),MODE_MINLOT)) LotMM=MarketInfo(Symbol(),MODE_MINLOT);
         ticket=OrderSend(Symbol(),OP_BUYLIMIT,LotMM,Entry,100,NormalizeDouble(SLPrice,Digits),TPPrice,DoubleToStr(OpenOrderRisk,2),magic,0,Green);
         err=GetLastError();
         if(ticket<=0) Alert("Error ",err);

        }
      // buy stop
      if(Entry!=0 && Bid<Entry && SLPrice<Entry)
        {
         StopLossPoints=(Entry-SLPrice)/TickSize;
         tradeVolume=(AccountBalance()*OpenOrderRisk/100)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));
         if(FixedTradeLoss) tradeVolume=(OpenOrderRisk)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));;
         LotStep=MarketInfo(Symbol(),MODE_LOTSTEP);
         LotMM=MathFloor(tradeVolume/LotStep)*LotStep;
         if(LotMM<MarketInfo(Symbol(),MODE_MINLOT)) LotMM=MarketInfo(Symbol(),MODE_MINLOT);
         ticket=OrderSend(Symbol(),OP_BUYSTOP,LotMM,Entry,100,NormalizeDouble(SLPrice,Digits),TPPrice,DoubleToStr(OpenOrderRisk,2),magic,0,Green);
         err=GetLastError();
         if(ticket<=0) Alert("Error ",err);

        }
      // sell limit
      if(Entry!=0 && Bid<Entry && SLPrice>Entry)
        {
         StopLossPoints=(SLPrice-Entry)/TickSize;
         tradeVolume=(AccountBalance()*OpenOrderRisk/100)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));
         if(FixedTradeLoss) tradeVolume=(OpenOrderRisk)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));;
         LotStep=MarketInfo(Symbol(),MODE_LOTSTEP);
         LotMM=MathFloor(tradeVolume/LotStep)*LotStep;
         if(LotMM<MarketInfo(Symbol(),MODE_MINLOT)) LotMM=MarketInfo(Symbol(),MODE_MINLOT);
         ticket=OrderSend(Symbol(),OP_SELLLIMIT,LotMM,Entry,100,NormalizeDouble(SLPrice,Digits),TPPrice,DoubleToStr(OpenOrderRisk,2),magic,0,Green);
         err=GetLastError();
         if(ticket<=0) Alert("Error ",err);

        }
      /// sell stop
      if(Entry!=0 && Bid>Entry && SLPrice>Entry)
        {
         StopLossPoints=(SLPrice-Entry)/TickSize;
         tradeVolume=(AccountBalance()*OpenOrderRisk/100)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));
         if(FixedTradeLoss) tradeVolume=(OpenOrderRisk)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));;
         LotStep=MarketInfo(Symbol(),MODE_LOTSTEP);
         LotMM=MathFloor(tradeVolume/LotStep)*LotStep;
         if(LotMM<MarketInfo(Symbol(),MODE_MINLOT)) LotMM=MarketInfo(Symbol(),MODE_MINLOT);
         ticket=OrderSend(Symbol(),OP_SELLSTOP,LotMM,Entry,100,NormalizeDouble(SLPrice,Digits),TPPrice,DoubleToStr(OpenOrderRisk,2),magic,0,Green);
         err=GetLastError();
         if(ticket<=0) Alert("Error ",err);

        }
     }
  }
//+------------------------------------------------------------------+
void Trade()
  {
   if(IsTradeAllowed())
     {

      RefreshRates();
      if(SLPrice<Bid)
        {

         StopLossPoints=(Ask-SLPrice)/TickSize;
         tradeVolume=(AccountBalance()*OpenOrderRisk/100)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));
         if(FixedTradeLoss) tradeVolume=(OpenOrderRisk)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));;
         LotStep=MarketInfo(Symbol(),MODE_LOTSTEP);
         LotMM=MathFloor(tradeVolume/LotStep)*LotStep;
         if(LotMM<MarketInfo(Symbol(),MODE_MINLOT)) LotMM=MarketInfo(Symbol(),MODE_MINLOT);
         ticket=OrderSend(Symbol(),OP_BUY,LotMM,Ask,100,0,0,DoubleToStr(OpenOrderRisk,2),magic,0,Green);
         err=GetLastError();
         if(ticket<=0) Alert("Error ",err);
         OrderModify(ticket,OrderOpenPrice(),SLPrice,TPPrice,0,CLR_NONE);

        }
      if(SLPrice>Bid)
        {
         StopLossPoints=(SLPrice-Bid)/TickSize;
         tradeVolume=(AccountBalance()*OpenOrderRisk/100)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));
         if(FixedTradeLoss) tradeVolume=(OpenOrderRisk)/(StopLossPoints*MarketInfo(Symbol(),MODE_TICKVALUE));;
         LotStep=MarketInfo(Symbol(),MODE_LOTSTEP);
         LotMM=MathFloor(tradeVolume/LotStep)*LotStep;
         if(LotMM<MarketInfo(Symbol(),MODE_MINLOT)) LotMM=MarketInfo(Symbol(),MODE_MINLOT);
         ticket=OrderSend(Symbol(),OP_SELL,LotMM,Bid,100,0,0,DoubleToStr(OpenOrderRisk,2),magic,0,Green);
         err=GetLastError();
         if(ticket<=0) Alert("Error ",err);
         OrderModify(ticket,OrderOpenPrice(),SLPrice,TPPrice,0,CLR_NONE);

        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RedrawLines()
  {
   Price=Close[0];
   ObjectDelete("InitStop");
   ObjectDelete("OpenPrice");
   ObjectDelete("TP");
   ObjectCreate("InitStop",1,0,0,Price+iATR(Symbol(),Period(),ATRPeriod(),0));
   ObjectSet("InitStop",6,Red);
   ObjectSet("InitStop",7,1);
   ObjectSetText("InitStop","Stop");

   ObjectCreate("OpenPrice",1,0,0,Price);
   ObjectSet("OpenPrice",6,Green);
   ObjectSet("OpenPrice",7,1);
   ObjectSetText("OpenPrice","Entry");

   ObjectCreate("TP",1,0,0,Price-iATR(Symbol(),Period(),ATRPeriod(),0));
   ObjectSet("TP",6,Blue);
   ObjectSet("TP",7,1);
   ObjectSetText("TP","Profit");
  }
//+------------------------------------------------------------------+
void SFP_Stop()
  {
   if(TPPrice<Level) ObjectSet("InitStop",1,NormalizeDouble(SLPrice+(SLPrice-Level)*0.25,Digits));

   if(TPPrice>Level) ObjectSet("InitStop",1,NormalizeDouble(SLPrice-(Level-SLPrice)*0.25,Digits));

  }
//+------------------------------------------------------------------+
void DeleteLines()
  {
   ObjectDelete("InitStop");
   ObjectDelete("OpenPrice");
   ObjectDelete("TP");
  }
//+------------------------------------------------------------------+
void drawSD(double Price,datetime time)
  {
   SetVis();
   TF();

   ObjectCreate("SD"+Price,2,0,time,Price,TimeCurrent(),Price);
   ObjectSet("SD"+Price,6,Color);
   ObjectSet("SD"+Price,OBJPROP_WIDTH,width);
   ObjectSet("SD"+Price,OBJPROP_TIMEFRAMES,vis);
   ObjectSet("SD"+Price,OBJPROP_RAY_RIGHT,false);
   ObjectSetText("SD"+Price,desc+" SD "+NormalizeDouble(Price,Digits));
//ObjectSetText("OpenPrice"+Price,desc+" "+NormalizeDouble(Price,Digits));
   ObjectCreate(ChartID(),"SDPrice"+Price,OBJ_ARROW_RIGHT_PRICE,0,TimeCurrent(),Price);
   ObjectSet("SDPrice"+Price,6,Color);
   ObjectSet("SDPrice"+Price,OBJPROP_WIDTH,width);
   ObjectSet("SDPrice"+Price,OBJPROP_TIMEFRAMES,vis);
   ObjectSet("SDPrice"+Price,OBJPROP_YDISTANCE,10);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TF()
  {
   space="               ";
   width=1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Period()==PERIOD_MN1)
     {
      Color= Red;
      desc = "M";
      width=1;
      style=2;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Period()==PERIOD_W1)
     {
      Color= Orange;
      desc = "W";
      width=1;
      style=1;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Period()==PERIOD_D1)
     {
      Color= Navy;
      desc = "D";
      width = 2;
      style = 1;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Period()==PERIOD_H4)
     {
      Color= Orange;
      desc = "H4";
      width=3;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Period()==PERIOD_H1)
     {
      Color= Yellow;
      desc = "H1";
      width=2;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Period()==PERIOD_M30)
     {
      Color= DarkGreen;
      desc = "M30";
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Period()==PERIOD_M15)
     {
      Color= MediumSeaGreen;
      desc = "M15";
      width=1;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Period()==PERIOD_M5)
     {
      Color= Lime;
      desc = "M5";
     }
   if(Period()==3)
     {
      Color= Lime;
      desc = "M3";
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Period()==PERIOD_M1)
     {
      Color= SpringGreen;
      desc = "M1";
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetVis()
  {
   vis=0;
   vis|=OBJ_PERIOD_M1;
   if(Period() >= PERIOD_M5) vis|= OBJ_PERIOD_M5;
   if(Period() >= PERIOD_M15) vis|= OBJ_PERIOD_M15;
   if(Period() >= PERIOD_M30) vis|= OBJ_PERIOD_M30;
   if(Period() >= PERIOD_H1) vis|= OBJ_PERIOD_H1;
   if(Period() >= PERIOD_H4) vis|= OBJ_PERIOD_H4;
   if(Period() >= PERIOD_D1) vis|= OBJ_PERIOD_D1;
   if(Period() >= PERIOD_W1) vis|= OBJ_PERIOD_W1;
   if(Period() >= PERIOD_MN1) vis|= OBJ_PERIOD_MN1;
   if(Period()==3) vis=0x01ff;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setSingleVis()
  {
   vis=0;
   vis=OBJ_PERIOD_M1;
   if(Period() >= PERIOD_M5) vis= OBJ_PERIOD_M5;
   if(Period() >= PERIOD_M15) vis= OBJ_PERIOD_M15;
   if(Period() >= PERIOD_M30) vis= OBJ_PERIOD_M30;
   if(Period() >= PERIOD_H1) vis= OBJ_PERIOD_H1;
   if(Period() >= PERIOD_H4) vis= OBJ_PERIOD_H4;
   if(Period() >= PERIOD_D1) vis= OBJ_PERIOD_D1;
   if(Period() >= PERIOD_W1) vis= OBJ_PERIOD_W1;
   if(Period() >= PERIOD_MN1) vis= OBJ_PERIOD_MN1;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+  

bool NewBar()
  {
   if(NewBarTime!=Time[0])
     {
      NewBarTime=Time[0];

      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void shiftSD()
  {
   datetime timeForward;
   int obj_total=ObjectsTotal();
   string name;
   string obj="SD";
   string obj1="SDPrice";
   timeForward= iTime(NULL,0,0)-iTime(NULL,0,1);
   for(int i=0;i<obj_total;i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      name=ObjectName(i);
      if(StringFind(name,obj,0)!=-1)
        {

         ObjectSet(name,OBJPROP_TIME2,TimeCurrent()+3*timeForward);
        }
      if(StringFind(name,obj1,0)!=-1)
        {
         ObjectSetInteger(0,name,OBJPROP_TIME,TimeCurrent()+3*timeForward);
        }
      if(ObjectType(name)==OBJ_RECTANGLE && !ObjectGetInteger(0,name,OBJPROP_BACK))
        {
         ObjectSetInteger(0,name,OBJPROP_TIME2,TimeCurrent()+3*timeForward);
        }

     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkSD()
  {
   int obj_total=ObjectsTotal();
   string name;
   string obj="SD";
   string obj1="SDPrice";

   for(int i=0;i<obj_total;i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      name=ObjectName(i);
      if(StringFind(name,obj,0)!=-1)
        {
         if(ObjectGet(name,OBJPROP_PRICE1)!=ObjectGet(name,OBJPROP_PRICE2)) ObjectSet(name,OBJPROP_PRICE2,ObjectGet(name,OBJPROP_PRICE1));
         string commonPrice=StringSubstr(name,2);
         ObjectSetDouble(0,"SDPrice"+commonPrice,OBJPROP_PRICE,ObjectGet(name,OBJPROP_PRICE1));
         ObjectSetText(name,desc+" SD "+NormalizeDouble(ObjectGet(name,OBJPROP_PRICE1),Digits));
         shiftSD();
        }

        {
         //   ObjectSetInteger(0,name,OBJPROP_TIME,Time[0]);
        }
     }
  }
//+------------------------------------------------------------------+
void drawPPZ(double Price)
  {
//int SFPBar=iBarShift(Symbol(),0,WindowTimeOnDropped(),false);
//double Price=Close[0];
   datetime SFPPrice=TimeLocal();
//double BarTime = WindowTimeOnDropped();
   SetVis();
   TF();
   ObjectCreate("PPZ"+SFPPrice,1,0,0,Price);
   ObjectSet("PPZ"+SFPPrice,6,Color);
   ObjectSet("PPZ"+SFPPrice,7,4);
   ObjectSetText("PPZ"+SFPPrice,desc+" PPZ");
   ObjectSet("PPZ"+SFPPrice,OBJPROP_TIMEFRAMES,vis);
   ObjectSet("PPZ"+SFPPrice,OBJPROP_BACK,false);
  }
//+------------------------------------------------------------------+

void createMenu()
  {
/*
   ObjectCreate("InitStop",1,0,0,Price+iATR(Symbol(),Period(),ATRPeriod(),0));
   ObjectSet("InitStop",6,Red);
   ObjectSet("InitStop",7,1);
   ObjectSetText("InitStop","Stop");

   ObjectCreate("OpenPrice",1,0,0,Price);
   ObjectSet("OpenPrice",6,Green);
   ObjectSet("OpenPrice",7,1);
   ObjectSetText("OpenPrice","Entry");

   ObjectCreate("TP",1,0,0,Price-iATR(Symbol(),Period(),ATRPeriod(),0));
   ObjectSet("TP",6,Blue);
   ObjectSet("TP",7,1);
   ObjectSetText("TP","Profit");
   */
   ObjectCreate("Volume",OBJ_LABEL,0,0,0);
   ObjectSet("Volume",OBJPROP_XDISTANCE,00);
   ObjectSet("Volume",OBJPROP_YDISTANCE,20);

   ObjectCreate("Margin",OBJ_LABEL,0,0,0);
   ObjectSet("Margin",OBJPROP_XDISTANCE,00);
   ObjectSet("Margin",OBJPROP_YDISTANCE,35);

   ObjectCreate("RR",OBJ_LABEL,0,0,0);
   ObjectSet("RR",OBJPROP_XDISTANCE,00);
   ObjectSet("RR",OBJPROP_YDISTANCE,50);

   ObjectCreate("AC",OBJ_LABEL,0,0,0);
   ObjectSet("AC",OBJPROP_XDISTANCE,00);
   ObjectSet("AC",OBJPROP_YDISTANCE,65);

   ObjectCreate("RISK",OBJ_LABEL,0,0,0);
   ObjectSet("RISK",OBJPROP_XDISTANCE,00);
   ObjectSet("RISK",OBJPROP_YDISTANCE,80);
   ObjectSetText("RISK","Risk");
   ObjectSet("RISK",OBJPROP_COLOR,White);

   ObjectCreate(ChartID(),"RiskSet",OBJ_EDIT,0,0,0);
   ObjectSetInteger(ChartID(),"RiskSet",OBJPROP_XDISTANCE,30);
   ObjectSetInteger(ChartID(),"RiskSet",OBJPROP_YDISTANCE,80);
   ObjectSetString(ChartID(),"RiskSet",OBJPROP_TEXT,"1");
   ObjectSetInteger(ChartID(),"RiskSet",OBJPROP_COLOR,Black);
   ObjectSetInteger(ChartID(),"RiskSet",OBJPROP_XSIZE,40);
   ObjectSetInteger(ChartID(),"RiskSet",OBJPROP_YSIZE,20);
   ObjectSetInteger(ChartID(),"RiskSet",OBJPROP_BGCOLOR,White);



//ButtonCreate("Menu","Menu",250,0,Red);
   ButtonCreate("Trade","Market",300,0,Red);
   ButtonCreate("Redraw","Draw lines",500,0,Blue);
   ButtonCreate("Pending","Limit",350,0,DarkGreen);
   ButtonCreate("SFP_Stop","Wiggle",450,0,Red);
   ButtonCreate("POO","Limit nonFX",400,0,Green);
   ButtonCreate("Hide","Hide lines",550,0,Blue);
//ButtonCreate("Snap","Snap",600,0,Blue);
   snapCheckBox.Create(0,"snapCheckBox",0,600,0,645,20);
   snapCheckBox.Text("Snap");
   sdCheckBox.Create(0,"sdCheckBox",0,650,0,695,20);
   sdCheckBox.Text("SD");
   ppzCheckBox.Create(0,"ppzCheckBox",0,700,0,745,20);
   ppzCheckBox.Text("PPZ");
   multiChartsButton.Create(0,"multiChartsButton",0,750,0,795,20);
   multiChartsButton.Text("MC");
   addSpread.Create(0,"addSpread",0,800,0,895,20);
   addSpread.Text("Add Spread");
   spread=(MarketInfo(Symbol(),MODE_SPREAD))*Point;

   Main();
   shiftSD();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void destroy()
  {
   ObjectDelete("Volume");
   ObjectDelete("Margin");
   ObjectDelete("RR");
   ObjectDelete("AC");
   ObjectDelete("RISK");
   ObjectDelete("RiskSet");
   ObjectDelete("Trade");
   ObjectDelete("Redraw");
   ObjectDelete("Pending");
   ObjectDelete("SFP_Stop");
   ObjectDelete("POO");
   ObjectDelete("Hide");
   snapCheckBox.Destroy();
   sdCheckBox.Destroy();
   ppzCheckBox.Destroy();
   multiChartsButton.Destroy();
   addSpread.Destroy();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createPriceLabel(string name)
  {
   double Price;
   Price=ObjectGet(name,OBJPROP_PRICE1);

   ObjectCreate(ChartID(),"SDPrice1"+name,OBJ_ARROW_RIGHT_PRICE,0,TimeCurrent(),Price);
   ObjectSet("SDPrice1"+name,6,Color);
   ObjectSet("SDPrice1"+name,OBJPROP_WIDTH,width);
   ObjectSet("SDPrice1"+name,OBJPROP_TIMEFRAMES,vis);
   ObjectSet("SDPrice1"+name,OBJPROP_YDISTANCE,10);
//ObjectSetText("SDPrice"+Price,name);

   Price=ObjectGet(name,OBJPROP_PRICE2);
   ObjectCreate(ChartID(),"SDPrice2"+name,OBJ_ARROW_RIGHT_PRICE,0,TimeCurrent(),Price);
   ObjectSet("SDPrice2"+name,6,Color);
   ObjectSet("SDPrice2"+name,OBJPROP_WIDTH,width);
   ObjectSet("SDPrice2"+name,OBJPROP_TIMEFRAMES,vis);
   ObjectSet("SDPrice2"+name,OBJPROP_YDISTANCE,10);
//ObjectSetText("SDPrice"+Price,name);
   ChartRedraw();
  }
//+------------------------------------------------------------------+
void deletePriceLabels(string name)
  {
   string name1;
   int obj_total=ObjectsTotal();
   for(int i=0;i<=obj_total;i++)
     {
      name1=ObjectName(i);
      if(ObjectGetString(0,name1,OBJPROP_TEXT)==name)
        {
         ObjectDelete(0,name1);
        }

     }
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void movePriceLabels(string name)
  {
   ObjectSetDouble(0,"SDPrice1"+name,OBJPROP_PRICE1,ObjectGetDouble(0,name,OBJPROP_PRICE1));
   ObjectSetDouble(0,"SDPrice2"+name,OBJPROP_PRICE1,ObjectGetDouble(0,name,OBJPROP_PRICE2));
  }
//+------------------------------------------------------------------+

bool isEntryLevelsExists()
  {
   if(ObjectGet("InitStop",1) == ObjectGet("OpenPrice",1)) return (false);
   if(ObjectGet("InitStop",1) != 0 && ObjectGet("TP",1) != 0 && ObjectGet("OpenPrice",1) !=0) return (true);
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addSpreadToEntry()
  {
   if(ObjectGetInteger(0,"OpenPrice",OBJPROP_SELECTED,0)==true) ObjectSet("OpenPrice",1,ObjectGet("OpenPrice",1)+spread);
   if(ObjectGetInteger(0,"TP",OBJPROP_SELECTED,0)==true) ObjectSet("TP",1,ObjectGet("TP",1)-spread);
   if(ObjectGetInteger(0,"InitStop",OBJPROP_SELECTED,0)==true) ObjectSet("InitStop",1,ObjectGet("InitStop",1)+spread);
  }
//+------------------------------------------------------------------+
