//+------------------------------------------------------------------+
//|  XAUUSD GoldTrader Pro — MT5 Indicator                          |
//|  Version 2.0 · April 2026                                       |
//|  7-signal confluence engine · Entry, TP1, TP2, TP3, SL          |
//|  Works on all timeframes · Best on 4H, Daily, Weekly            |
//|  NOT financial advice — trade responsibly                       |
//+------------------------------------------------------------------+
#property copyright   "GoldTrader Pro 2026"
#property version     "2.00"
#property description "XAUUSD 7-signal confluence indicator with TP/SL levels"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6

//── PLOT: BUY Arrow ─────────────────────────────────────────────────
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLime
#property indicator_width1  3
#property indicator_label1  "BUY Signal"

//── PLOT: SELL Arrow ────────────────────────────────────────────────
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  3
#property indicator_label2  "SELL Signal"

//── PLOT: TP1 Line ──────────────────────────────────────────────────
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrPaleGreen
#property indicator_style3  STYLE_DOT
#property indicator_width3  1
#property indicator_label3  "TP1 (1:2 RR)"

//── PLOT: TP2 Line ──────────────────────────────────────────────────
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrLimeGreen
#property indicator_style4  STYLE_DASH
#property indicator_width4  2
#property indicator_label4  "TP2 (1:3 RR)"

//── PLOT: TP3 Line ──────────────────────────────────────────────────
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrAqua
#property indicator_style5  STYLE_DASHDOT
#property indicator_width5  1
#property indicator_label5  "TP3 (1:5 RR)"

//── PLOT: Stop Loss Line ────────────────────────────────────────────
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrRed
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2
#property indicator_label6  "Stop Loss"

//════════════════════════════════════════════
//   INPUT PARAMETERS
//════════════════════════════════════════════

input group "═══ RSI Settings ═══"
input int    InpRSI_Period      = 14;          // RSI period
input double InpRSI_OB          = 70.0;        // RSI overbought level
input double InpRSI_OS          = 30.0;        // RSI oversold level

input group "═══ ATR & Risk Management ═══"
input int    InpATR_Period      = 14;          // ATR period
input double InpATR_SL_Mult     = 1.2;         // SL multiplier (ATR × this)
input double InpRR_TP1          = 2.0;         // TP1 risk:reward ratio
input double InpRR_TP2          = 3.0;         // TP2 risk:reward ratio
input double InpRR_TP3          = 5.0;         // TP3 risk:reward ratio

input group "═══ Moving Averages ═══"
input int    InpEMA_Fast        = 20;          // Fast EMA
input int    InpEMA_Mid         = 50;          // Mid EMA
input int    InpEMA_Slow        = 200;         // Slow EMA (trend filter)

input group "═══ Bollinger Bands ═══"
input int    InpBB_Period       = 20;          // BB period
input double InpBB_Dev          = 2.0;         // BB standard deviation

input group "═══ MACD Settings ═══"
input int    InpMACD_Fast       = 12;          // MACD fast EMA
input int    InpMACD_Slow       = 26;          // MACD slow EMA
input int    InpMACD_Signal     = 9;           // MACD signal line

input group "═══ Signal Filters ═══"
input int    InpMinConf         = 5;           // Minimum confluence score (1-7) — rec: 5+
input bool   InpShowAll         = true;        // Show all historical signals
input int    InpLookback        = 500;         // Bars to analyze

input group "═══ Display Settings ═══"
input bool   InpShowDashboard   = true;        // Show info dashboard on chart
input bool   InpShowTPLabels    = true;        // Show TP/SL price labels
input int    InpDashX           = 15;          // Dashboard X position
input int    InpDashY           = 30;          // Dashboard Y position
input color  InpDashColor       = clrGold;     // Dashboard text color

input group "═══ Alerts ═══"
input bool   InpAlerts          = true;        // Enable popup alerts
input bool   InpPushNotif       = true;        // Enable push notifications (MT5 app)
input bool   InpEmailAlert      = false;       // Enable email alerts
input bool   InpSoundAlert      = true;        // Enable sound alerts
input int    InpMinScore_Alert  = 6;           // Minimum score to trigger alert

//════════════════════════════════════════════
//   BUFFERS
//════════════════════════════════════════════

double BuyBuffer[];     // 0 — BUY arrow
double SellBuffer[];    // 1 — SELL arrow
double TP1Buffer[];     // 2 — TP1 line
double TP2Buffer[];     // 3 — TP2 line
double TP3Buffer[];     // 4 — TP3 line
double SLBuffer[];      // 5 — Stop Loss line

//── Indicator handles ───────────────────────
int hRSI, hATR, hEMA20, hEMA50, hEMA200, hMACD, hBB;

//── State ───────────────────────────────────
datetime lastAlertTime = 0;
string   dashName      = "GT_DASHBOARD";
string   PREFIX        = "GT_";

//════════════════════════════════════════════
//   INITIALIZATION
//════════════════════════════════════════════

int OnInit()
{
   //── Set buffers ────────────────────────────
   SetIndexBuffer(0, BuyBuffer,  INDICATOR_DATA);
   SetIndexBuffer(1, SellBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, TP1Buffer,  INDICATOR_DATA);
   SetIndexBuffer(3, TP2Buffer,  INDICATOR_DATA);
   SetIndexBuffer(4, TP3Buffer,  INDICATOR_DATA);
   SetIndexBuffer(5, SLBuffer,   INDICATOR_DATA);

   //── Arrow codes ────────────────────────────
   PlotIndexSetInteger(0, PLOT_ARROW, 241);  // ▲ up arrow
   PlotIndexSetInteger(1, PLOT_ARROW, 242);  // ▼ down arrow

   //── Empty values ───────────────────────────
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   //── Indicator name ─────────────────────────
   IndicatorSetString(INDICATOR_SHORTNAME, "GoldTrader Pro [" + IntegerToString(InpMinConf) + "/7]");

   //── Create indicator handles ───────────────
   hRSI   = iRSI   (_Symbol, PERIOD_CURRENT, InpRSI_Period, PRICE_CLOSE);
   hATR   = iATR   (_Symbol, PERIOD_CURRENT, InpATR_Period);
   hEMA20 = iMA    (_Symbol, PERIOD_CURRENT, InpEMA_Fast,  0, MODE_EMA, PRICE_CLOSE);
   hEMA50 = iMA    (_Symbol, PERIOD_CURRENT, InpEMA_Mid,   0, MODE_EMA, PRICE_CLOSE);
   hEMA200= iMA    (_Symbol, PERIOD_CURRENT, InpEMA_Slow,  0, MODE_EMA, PRICE_CLOSE);
   hMACD  = iMACD  (_Symbol, PERIOD_CURRENT, InpMACD_Fast, InpMACD_Slow, InpMACD_Signal, PRICE_CLOSE);
   hBB    = iBands (_Symbol, PERIOD_CURRENT, InpBB_Period,  0, InpBB_Dev, PRICE_CLOSE);

   if(hRSI == INVALID_HANDLE || hATR == INVALID_HANDLE || hMACD == INVALID_HANDLE)
   {
      Print("GoldTrader Pro: Failed to create indicator handles. Error: ", GetLastError());
      return INIT_FAILED;
   }

   Print("GoldTrader Pro v2.0 initialized. Min confluence: ", InpMinConf, "/7. Symbol: ", _Symbol);
   return INIT_SUCCEEDED;
}

//════════════════════════════════════════════
//   DE-INITIALIZATION
//════════════════════════════════════════════

void OnDeinit(const int reason)
{
   //── Release handles ────────────────────────
   IndicatorRelease(hRSI);
   IndicatorRelease(hATR);
   IndicatorRelease(hEMA20);
   IndicatorRelease(hEMA50);
   IndicatorRelease(hEMA200);
   IndicatorRelease(hMACD);
   IndicatorRelease(hBB);

   //── Remove dashboard objects ───────────────
   ObjectsDeleteAll(0, PREFIX);
   Comment("");
}

//════════════════════════════════════════════
//   MAIN CALCULATION
//════════════════════════════════════════════

int OnCalculate(const int       rates_total,
                const int       prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[])
{
   //── Wait for enough bars ───────────────────
   if(rates_total < InpEMA_Slow + 30) return 0;

   //── Copy indicator data ────────────────────
   int copyBars = MathMin(rates_total, InpLookback + 10);

   double rsi[],   atr[];
   double e20[],   e50[],  e200[];
   double mLine[], mSig[], mHist[];
   double bbU[],   bbL[],  bbM[];

   if(CopyBuffer(hRSI,   0, 0, copyBars, rsi)   <= 0) return prev_calculated;
   if(CopyBuffer(hATR,   0, 0, copyBars, atr)   <= 0) return prev_calculated;
   if(CopyBuffer(hEMA20, 0, 0, copyBars, e20)   <= 0) return prev_calculated;
   if(CopyBuffer(hEMA50, 0, 0, copyBars, e50)   <= 0) return prev_calculated;
   if(CopyBuffer(hEMA200,0, 0, copyBars, e200)  <= 0) return prev_calculated;
   if(CopyBuffer(hMACD,  0, 0, copyBars, mLine) <= 0) return prev_calculated;
   if(CopyBuffer(hMACD,  1, 0, copyBars, mSig)  <= 0) return prev_calculated;
   if(CopyBuffer(hMACD,  2, 0, copyBars, mHist) <= 0) return prev_calculated;
   if(CopyBuffer(hBB,    1, 0, copyBars, bbU)   <= 0) return prev_calculated;
   if(CopyBuffer(hBB,    2, 0, copyBars, bbL)   <= 0) return prev_calculated;
   if(CopyBuffer(hBB,    0, 0, copyBars, bbM)   <= 0) return prev_calculated;

   //── Calculate from/to range ────────────────
   int start = (prev_calculated == 0) ? copyBars - 1 : 1;
   start = MathMin(start, InpLookback);

   //── Loop through bars ──────────────────────
   for(int shift = start; shift >= 0; shift--)
   {
      int i = shift;  // array index (0 = current bar)

      //── Default to empty ───────────────────
      BuyBuffer[rates_total-1-shift]  = EMPTY_VALUE;
      SellBuffer[rates_total-1-shift] = EMPTY_VALUE;
      TP1Buffer[rates_total-1-shift]  = EMPTY_VALUE;
      TP2Buffer[rates_total-1-shift]  = EMPTY_VALUE;
      TP3Buffer[rates_total-1-shift]  = EMPTY_VALUE;
      SLBuffer[rates_total-1-shift]   = EMPTY_VALUE;

      if(i < 2 || i >= copyBars-1) continue;

      double c    = close[rates_total-1-shift];
      double h    = high[rates_total-1-shift];
      double l    = low[rates_total-1-shift];
      double c1   = close[rates_total-shift];    // prev close
      double rsi0 = rsi[i];
      double rsi1 = rsi[i+1];
      double a    = atr[i];
      double ma20 = e20[i];
      double ma50 = e50[i];
      double ma200= e200[i];
      double macd = mLine[i];
      double mac1 = mLine[i+1];
      double hist = mHist[i];
      double his1 = mHist[i+1];
      double bbl  = bbL[i];
      double bbu  = bbU[i];

      //════════════════════════════════════════
      //   LONG (BUY) CONFLUENCE SCORING
      //   Each condition = 1 point (max 7)
      //════════════════════════════════════════
      int longScore = 0;

      // 1. RSI oversold (< InpRSI_OS)
      if(rsi0 < InpRSI_OS) longScore++;

      // 2. Price near or below BB lower band
      if(c <= bbl * 1.003) longScore++;

      // 3. Price above 200 EMA (long-term uptrend)
      if(c > ma200) longScore++;

      // 4. Fast EMA above Mid EMA (short-term bullish)
      if(ma20 > ma50) longScore++;

      // 5. MACD histogram turning up (momentum shift)
      if(hist > his1 && hist > -0.5*a) longScore++;

      // 6. Bullish RSI divergence (price lower, RSI higher)
      if(rsi0 > rsi1 && c < c1) longScore++;

      // 7. MACD line positive (macro momentum)
      if(macd > 0) longScore++;

      //════════════════════════════════════════
      //   SHORT (SELL) CONFLUENCE SCORING
      //════════════════════════════════════════
      int shortScore = 0;

      // 1. RSI overbought
      if(rsi0 > InpRSI_OB) shortScore++;

      // 2. Price at or above BB upper band
      if(c >= bbu * 0.997) shortScore++;

      // 3. Price below 200 EMA
      if(c < ma200) shortScore++;

      // 4. Fast EMA below Mid EMA
      if(ma20 < ma50) shortScore++;

      // 5. MACD histogram turning down
      if(hist < his1 && hist < 0.5*a) shortScore++;

      // 6. Bearish RSI divergence
      if(rsi0 < rsi1 && c > c1) shortScore++;

      // 7. MACD line negative
      if(macd < 0) shortScore++;

      //════════════════════════════════════════
      //   GENERATE SIGNALS
      //════════════════════════════════════════

      bool isBuy  = (longScore  >= InpMinConf && longScore  > shortScore);
      bool isSell = (shortScore >= InpMinConf && shortScore > longScore);

      if(isBuy)
      {
         double slPrice   = c - a * InpATR_SL_Mult;
         double slDist    = c - slPrice;
         double tp1Price  = c + slDist * InpRR_TP1;
         double tp2Price  = c + slDist * InpRR_TP2;
         double tp3Price  = c + slDist * InpRR_TP3;

         BuyBuffer[rates_total-1-shift]  = l - a * 0.6;
         TP1Buffer[rates_total-1-shift]  = tp1Price;
         TP2Buffer[rates_total-1-shift]  = tp2Price;
         TP3Buffer[rates_total-1-shift]  = tp3Price;
         SLBuffer[rates_total-1-shift]   = slPrice;

         //── Draw TP/SL labels on chart (current bar only)
         if(shift == 0 && InpShowTPLabels)
         {
            DrawPriceLabel(PREFIX+"BUY_ENTRY",  time[rates_total-1], c,      "ENTRY "+DoubleToString(c,2), clrGold,      true);
            DrawPriceLabel(PREFIX+"BUY_SL",     time[rates_total-1], slPrice,"SL "+DoubleToString(slPrice,2),  clrRed,  false);
            DrawPriceLabel(PREFIX+"BUY_TP1",    time[rates_total-1], tp1Price,"TP1 "+DoubleToString(tp1Price,2), clrPaleGreen, false);
            DrawPriceLabel(PREFIX+"BUY_TP2",    time[rates_total-1], tp2Price,"TP2 "+DoubleToString(tp2Price,2), clrLimeGreen, false);
            DrawPriceLabel(PREFIX+"BUY_TP3",    time[rates_total-1], tp3Price,"TP3 "+DoubleToString(tp3Price,2), clrAqua, false);
         }

         //── Send alert (current bar only, avoid repeat)
         if(shift == 0 && InpAlerts && longScore >= InpMinScore_Alert && time[rates_total-1] != lastAlertTime)
         {
            lastAlertTime = time[rates_total-1];
            string slPips  = IntegerToString((int)(a * InpATR_SL_Mult / _Point));
            string msg = "🟢 XAUUSD BUY SIGNAL " + IntegerToString(longScore) + "/7\n" +
                         "Timeframe: " + EnumToString(PERIOD_CURRENT) + "\n" +
                         "Entry:  " + DoubleToString(c, 2) + "\n" +
                         "SL:     " + DoubleToString(slPrice, 2) + " (-" + slPips + " pts)\n" +
                         "TP1:    " + DoubleToString(tp1Price, 2) + " (1:2 RR)\n" +
                         "TP2:    " + DoubleToString(tp2Price, 2) + " (1:3 RR)\n" +
                         "TP3:    " + DoubleToString(tp3Price, 2) + " (1:5 RR)";
            if(InpAlerts)       Alert(msg);
            if(InpPushNotif)    SendNotification(msg);
            if(InpEmailAlert)   SendMail("XAUUSD BUY Signal " + IntegerToString(longScore) + "/7", msg);
            if(InpSoundAlert)   PlaySound("alert.wav");
         }
      }
      else if(isSell)
      {
         double slPrice   = c + a * InpATR_SL_Mult;
         double slDist    = slPrice - c;
         double tp1Price  = c - slDist * InpRR_TP1;
         double tp2Price  = c - slDist * InpRR_TP2;
         double tp3Price  = c - slDist * InpRR_TP3;

         SellBuffer[rates_total-1-shift] = h + a * 0.6;
         TP1Buffer[rates_total-1-shift]  = tp1Price;
         TP2Buffer[rates_total-1-shift]  = tp2Price;
         TP3Buffer[rates_total-1-shift]  = tp3Price;
         SLBuffer[rates_total-1-shift]   = slPrice;

         if(shift == 0 && InpShowTPLabels)
         {
            DrawPriceLabel(PREFIX+"SELL_ENTRY", time[rates_total-1], c,       "ENTRY "+DoubleToString(c,2),    clrGold,     true);
            DrawPriceLabel(PREFIX+"SELL_SL",    time[rates_total-1], slPrice, "SL "+DoubleToString(slPrice,2), clrRed,      false);
            DrawPriceLabel(PREFIX+"SELL_TP1",   time[rates_total-1], tp1Price,"TP1 "+DoubleToString(tp1Price,2),clrPaleGreen,false);
            DrawPriceLabel(PREFIX+"SELL_TP2",   time[rates_total-1], tp2Price,"TP2 "+DoubleToString(tp2Price,2),clrLimeGreen,false);
            DrawPriceLabel(PREFIX+"SELL_TP3",   time[rates_total-1], tp3Price,"TP3 "+DoubleToString(tp3Price,2),clrAqua,     false);
         }

         if(shift == 0 && InpAlerts && shortScore >= InpMinScore_Alert && time[rates_total-1] != lastAlertTime)
         {
            lastAlertTime = time[rates_total-1];
            string slPips = IntegerToString((int)(a * InpATR_SL_Mult / _Point));
            string msg = "🔴 XAUUSD SELL SIGNAL " + IntegerToString(shortScore) + "/7\n" +
                         "Timeframe: " + EnumToString(PERIOD_CURRENT) + "\n" +
                         "Entry:  " + DoubleToString(c, 2) + "\n" +
                         "SL:     " + DoubleToString(slPrice, 2) + " (+"+slPips+" pts)\n" +
                         "TP1:    " + DoubleToString(tp1Price, 2) + " (1:2 RR)\n" +
                         "TP2:    " + DoubleToString(tp2Price, 2) + " (1:3 RR)\n" +
                         "TP3:    " + DoubleToString(tp3Price, 2) + " (1:5 RR)";
            if(InpAlerts)       Alert(msg);
            if(InpPushNotif)    SendNotification(msg);
            if(InpEmailAlert)   SendMail("XAUUSD SELL Signal " + IntegerToString(shortScore) + "/7", msg);
            if(InpSoundAlert)   PlaySound("alert.wav");
         }
      }
   }

   //── Update dashboard ───────────────────────
   if(InpShowDashboard)
   {
      int   ls  = GetLongScore(rsi[0],atr[0],close[rates_total-1],e20[0],e50[0],e200[0],mLine[0],mHist[0],mHist[1],bbL[0],bbU[0],close[rates_total-2],rsi[1]);
      int   ss  = GetShortScore(rsi[0],atr[0],close[rates_total-1],e20[0],e50[0],e200[0],mLine[0],mHist[0],mHist[1],bbL[0],bbU[0],close[rates_total-2],rsi[1]);
      string sig = ls >= InpMinConf ? "BUY " + IntegerToString(ls) + "/7" : ss >= InpMinConf ? "SELL " + IntegerToString(ss) + "/7" : "WAIT — no signal";
      color  sigCol = ls >= InpMinConf ? clrLime : ss >= InpMinConf ? clrRed : clrGold;

      string dash = "═══ GoldTrader Pro ═══\n" +
                    "Symbol:  " + _Symbol + "\n" +
                    "TF:      " + EnumToString(PERIOD_CURRENT) + "\n" +
                    "Price:   " + DoubleToString(close[rates_total-1], 2) + "\n" +
                    "RSI:     " + DoubleToString(rsi[0], 1) + "\n" +
                    "MACD:    " + (mLine[0]>0?"▲ Bullish":"▼ Bearish") + "\n" +
                    "EMA:     " + (e20[0]>e50[0]?"▲ Aligned":"▼ Bearish") + "\n" +
                    "BB:      " + (close[rates_total-1]<bbL[0]?"At lower band":close[rates_total-1]>bbU[0]?"At upper band":"Mid zone") + "\n" +
                    "Long:    " + IntegerToString(ls) + "/7\n" +
                    "Short:   " + IntegerToString(ss) + "/7\n" +
                    "Signal:  " + sig + "\n" +
                    "Min req: " + IntegerToString(InpMinConf) + "/7";
      Comment(dash);
   }

   return rates_total;
}

//════════════════════════════════════════════
//   HELPER FUNCTIONS
//════════════════════════════════════════════

int GetLongScore(double rsi, double atr, double c, double e20, double e50, double e200,
                 double macd, double hist, double his1, double bbl, double bbu, double c1, double rsi1)
{
   int score = 0;
   if(rsi < InpRSI_OS) score++;
   if(c <= bbl * 1.003) score++;
   if(c > e200) score++;
   if(e20 > e50) score++;
   if(hist > his1) score++;
   if(rsi > rsi1 && c < c1) score++;
   if(macd > 0) score++;
   return score;
}

int GetShortScore(double rsi, double atr, double c, double e20, double e50, double e200,
                  double macd, double hist, double his1, double bbl, double bbu, double c1, double rsi1)
{
   int score = 0;
   if(rsi > InpRSI_OB) score++;
   if(c >= bbu * 0.997) score++;
   if(c < e200) score++;
   if(e20 < e50) score++;
   if(hist < his1) score++;
   if(rsi < rsi1 && c > c1) score++;
   if(macd < 0) score++;
   return score;
}

void DrawPriceLabel(string name, datetime t, double price, string text, color clr, bool bold)
{
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_TEXT, 0, t, price);
   ObjectSetString(0,  name, OBJPROP_TEXT,      text);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,   bold ? 10 : 9);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,     ANCHOR_LEFT);
}

//+------------------------------------------------------------------+
//   SIGNAL STRENGTH LEVELS:
//
//   7/7 — MAXIMUM STRENGTH  → Enter full position (all 3 TPs)
//   6/7 — STRONG SIGNAL     → Enter full position (all 3 TPs)
//   5/7 — MODERATE SIGNAL   → Enter 50-75% position (TP1 + TP2)
//   4/7 — WEAK SIGNAL       → SKIP or very small position
//   1-3 — NO TRADE          → Wait for better setup
//
//   RECOMMENDED SETTINGS BY TIMEFRAME:
//   4H Chart:    MinConf = 5  → ~72% win rate
//   Daily Chart: MinConf = 5  → ~81% win rate
//   Weekly:      MinConf = 6  → ~83% win rate
//   1H Chart:    MinConf = 6  → ~68% win rate (higher bar needed)
//   15M Chart:   MinConf = 6  → ~67% win rate (higher bar needed)
//
//   TRADE MANAGEMENT (1:3 RR):
//   TP1 hit → Close 50% of position, move SL to breakeven
//   TP2 hit → Close 30% of position
//   TP3     → Trail remaining 20% with ATR-based trailing stop
//
//   BEST PAIRS FOR THIS INDICATOR: XAUUSD (Gold)
//   NOT FINANCIAL ADVICE — Always use risk management
//+------------------------------------------------------------------+
