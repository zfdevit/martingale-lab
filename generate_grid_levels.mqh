//+------------------------------------------------------------------+
//|                                         Generate_Grid_Levels.mqh |
//|                                                    amended by ZF |
//+------------------------------------------------------------------+

// User option
enum MARTINGALE_TYPE{
   classic_martingale,                            // Classic
   mini_martingale,                               // Mini
   equal_martingale,                              // Equal
};

// calculate the grid levels for selected ticker
void CalculateGridLevels(const string symbol, const double step, const int levels_above, const int levels_below, double &grid[])
{
   double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
   if (current_price == 0)
      return;
      
   int total_levels = levels_above + levels_below + 1;
   ArrayResize(grid, total_levels);
   
   for(int i = -levels_below; i <= levels_above; i++)
      grid[i + levels_below] = current_price + i * step * SymbolInfoDouble(symbol, SYMBOL_POINT);
}

void CalculateGridSize(MARTINGALE_TYPE martingale_type, const string symbol, const double step, int grid_levels, double increment_factor, double total_investment, double &grid[], double &grid_size[])
{  
   // Calculate grid price
   double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
   if (current_price == 0)
      return;
      
   int total_levels = grid_levels + grid_levels + 1;
   ArrayResize(grid, total_levels);
   
   for(int i = -grid_levels; i <= grid_levels; i++)
      grid[i + grid_levels] = current_price + i * step * SymbolInfoDouble(symbol, SYMBOL_POINT);

   // Validate inputs
   if (grid_levels <= 0 || increment_factor < 0 || total_investment <= 0)
   {
      Print("Invalid parameters: grid_levels, increment_factor, or total_investment.");
      return;
   }

   // Declare and resize grid_size array
   ArrayResize(grid_size, grid_levels);
   double cumulative_size = 0.0;

   Print("Martingale Type: ", martingale_type);
   Print("Level | Current | Grid |  Size");

   if (martingale_type == classic_martingale)
   {
      // Classic Martingale: Sizes double at each level
      for (int i = 0; i < grid_levels; i++)
      {
         grid_size[i] = (i == 0) ? total_investment / MathPow(2, grid_levels - 1) : grid_size[i - 1] * 2;
         cumulative_size += grid_size[i];

         if(cumulative_size < total_investment || cumulative_size == total_investment)
         {
            Print(i + 1, " | ", current_price, " | ", DoubleToString(grid[i + grid_levels], 3), " | ", DoubleToString(grid_size[i], 2));
         }
         else
         {
            Print("Invalid cumulative size.");
         }
         
      }
   }
   else if (martingale_type == mini_martingale)
   {
      // Mini Martingale: Sizes increase by the increment factor
      double total_weight = 0.0;
      for (int i = 0; i < grid_levels; i++)
      {
         total_weight += MathPow(1 + increment_factor, i);
      }
      double base_size = total_investment / total_weight;

      for (int i = 0; i < grid_levels; i++)
      {
         grid_size[i] = base_size * MathPow(1 + increment_factor, i);
         cumulative_size += grid_size[i];
         
         if(cumulative_size < total_investment || cumulative_size == total_investment)
         {
            Print(i + 1, " | ", current_price, " | ", DoubleToString(grid[i + grid_levels], 3), " | ", DoubleToString(grid_size[i], 2));
         }
         else
         {
            Print("Invalid cumulative size.");
         }
      }
   }
   else if (martingale_type == equal_martingale)
   {
      // Equal Martingale: Same size for all levels
      double equal_size = total_investment / grid_levels;

      for (int i = 0; i < grid_levels; i++)
      {
         grid_size[i] = equal_size;
         cumulative_size += grid_size[i];
         
         if(cumulative_size < total_investment || cumulative_size == total_investment)
         {
            Print(i + 1, " | ", current_price, " | ", DoubleToString(grid[i + grid_levels], 3), " | ", DoubleToString(grid_size[i], 2));
         }
         else
         {
            Print("Invalid cumulative size.");
         }
      }
   }
   else
   {
      Print("Invalid martingale type.");
      return;
   }

   // Final check for total investment
   if (cumulative_size > total_investment)
   {
      Print("Total Allocated: ", DoubleToString(cumulative_size, 2), " WARNING: Cumulative size exceeds total investment! Recalculate...");
      double scale_factor = total_investment/cumulative_size;

      for (int i = 0; i < grid_levels; i++)
      {
         grid_size[i] *= scale_factor;
      }

      cumulative_size = 0.0;

      for (int i = 0; i < grid_levels; i++)
      {
         cumulative_size += grid_size[i];
      }

      Print("Total Allocated Updated: ", DoubleToString(cumulative_size, 2));
   }
   else
   {
      Print("Total Allocated: ", DoubleToString(cumulative_size, 2));
   }
}


// draw grid levels on the chart
void DrawGridLevels(const string prefix, const color grid_color, double &grid[], const int levels_above, const int levels_below)
{
   // middle of the grid
   double current_price = grid[levels_below];

   for (int i = 0; i < ArraySize(grid); i++)
   {
      string line_name = prefix + IntegerToString(i - levels_below);

      color line_color;

      if(grid[i] > current_price)
         line_color = clrGreen;      // buy stop levels
      else if(grid[i] < current_price)
         line_color = clrRed;        // sell stop levels
      else
         line_color = clrBlue;       // current price
      
      if (ObjectFind(0, line_name) == -1)
      {
         ObjectCreate(0, line_name, OBJ_HLINE, 0, 0, grid[i]);
         ObjectSetInteger(0, line_name, OBJPROP_COLOR, line_color);
         ObjectSetInteger(0, line_name, OBJPROP_STYLE, STYLE_DASHDOT);
         ObjectSetInteger(0, line_name, OBJPROP_WIDTH, 1);
      }
      else
      {
         ObjectSetDouble(0, line_name, OBJPROP_PRICE, grid[i]);
         ObjectSetInteger(0, line_name, OBJPROP_COLOR, line_color);
      }
   }
}

// save grid levels in csv
void SaveGridToCSV(const string ticker, double &grid[], const int levels_above, const int levels_below)
{
   string file_name = ticker + "_grid_levels.csv";

   int file_handle = FileOpen(file_name, FILE_WRITE | FILE_CSV);
   if (file_handle == INVALID_HANDLE)
   {
      Print("Error: Unable to open file ", file_name);
      return;
   }

   FileWrite(file_handle, "Level", "Price");
   for (int i = 0; i < ArraySize(grid); i++)
      FileWrite(file_handle, IntegerToString(i - levels_below), DoubleToString(grid[i], _Digits));
   
   FileClose(file_handle);
}

// update the grid levels when the current price changed
void UpdateGridLevels(const string ticker, const double step, const int levels_above, const int levels_below, double &grid[], const string prefix, const color grid_color)
{
   static double last_price = 0;
   double current_price = SymbolInfoDouble(ticker, SYMBOL_BID);

   if (MathAbs(current_price - last_price) >= step * SymbolInfoDouble(ticker, SYMBOL_POINT))
   {
      last_price = current_price;
      CalculateGridLevels(ticker, step, levels_above, levels_below, grid);
      DrawGridLevels(prefix, grid_color, grid, levels_above, levels_below);
      SaveGridToCSV(ticker, grid, levels_above, levels_below);
   }
}

// Load csv file
bool LoadGridFromCSV(const string file_name, double &grid[])
{
    int file_handle = FileOpen(file_name, FILE_READ | FILE_CSV);
    if (file_handle == INVALID_HANDLE)
    {
        Print("Error: Unable to open file ", file_name);
        return false;
    }

    ArrayResize(grid, 0);        // Reset the array
    FileReadString(file_handle); // Skip the header line

    while (!FileIsEnding(file_handle))
    {
        string level = FileReadString(file_handle);
        string price = FileReadString(file_handle);

        ArrayResize(grid, ArraySize(grid) + 1);
        grid[ArraySize(grid) - 1] = StringToDouble(price);
    }

    FileClose(file_handle);
    return true;
}

