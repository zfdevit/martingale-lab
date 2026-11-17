# Overview
A Multi-Level Martingale Grid strategy combines grid trading and Martingale techniques to capitalize on market price fluctuations.

# Key Concepts

## Grid Trading
Grid trading involves placing buy and sell orders at predetermined price intervals (grid levels). This method profits from price oscillations without predicting market direction.

## Martingale Strategy
Martingale is a position-sizing strategy where trade sizes increase after a loss, aiming to recover losses and achieve a profit:
1. Classic Martingale: Double the trade size after a loss.
2. Mini Martingale: Increase trade size by a smaller factor (e.g., 1.5x).
3. Equal Martingale: Maintain a fixed trade size across trades.

### Classic Martingale:
- Start with an initial lot size (e.g., 0.1 lots).
- After a loss, double the previous lot size (e.g., 0.1 → 0.2 → 0.4 → 0.8).
- This exponential growth aims to recover previous losses plus a profit equal to the initial lot size's profit target.
- Lot Size
  
### Mini Martingale:
- Start with an initial lot size.
- After a loss, increase the lot size by a smaller factor, such as 1.5x (e.g., 0.1 → 0.15 → 0.225 → 0.3375).
- Slower growth reduces risk but also decreases recovery speed.

### Equal Martingale:
- Maintain the same lot size across all trades (e.g., 0.1 lots).

* This approach avoids the risk of compounding losses but relies more heavily on grid-level oscillations for profitability.

## Steps to Calculate Lot Size with Martingale
1. Set Budget: Define the total budget available for trading.
2. Determine Cost Per Lot: Calculate the cost per lot based on the selected symbol's price, contract size, and leverage.
3. Allocate Budget for Martingale Levels: Divide the budget to accommodate all planned Martingale levels, ensuring the total lot cost does not exceed the budget.
4. Calculate Lot Sizes for Each Level: Use the chosen Martingale method to determine lot sizes for each level.
5. Check Feasibility: Ensure that the total margin required for all levels fits within the allocated budget.

- Classic Martingale (Suitable for aggressive strategies with fewer levels)
Calculation Logic:
Start with a small initial investment at the first level.
Double the position size at each subsequent level.
The total investment is divided across the levels, ensuring all levels stay within the total budget.

Example:
Total Investment: RM 10,000
Grid Levels: 7

Step-by-Step Calculation:
The position size doubles at each level:
Level 1: 𝑥
Level 2: 2𝑥
Level 3: 4𝑥
..., up to Level 7: 2^6𝑥
Total size = 𝑥 + 2𝑥 + 4𝑥 + ... + 2^6𝑥 = 𝑥 * (1 + 2 + 4+ ... + 64)
Sum of the series = 2^7 − 1 = 127
Base size at Level 1: 𝑥 = Total Investment / Sum of Weights = 10,000 / 127 = 78.74

Position sizes =
Level 1: 78.74
Level 2: 157.48
Level 3: 314.96
...
Level 7: 5033.28

- Mini Martingale (Balances risk and reward)
Calculation Logic:
Start with an initial position size.
Increase the size at each level by a fixed percentage (increment factor).
Total investment is distributed proportionally across all levels.

Example:

Total Investment: RM 10,000
Grid Levels: 7
Increment Factor: 50% (0.5)

Step-by-Step Calculation:

Each level increases by 1 + increment factor
Level 1: 𝑥
Level 2: 𝑥 * (1 + 0.5)
Level 3: 𝑥 * (1 + 0.5)^2
..., up to Level 7: 𝑥 * (1 + 0.5)^6

Total size = 𝑥 * [1 + (1 + 0.5) + (1 + 0.5)^2 + ... + (1 + 0.5)^6]


Sum of the series:
Sum of Weights = 1 + 1.5 + 2.25 + ... + 11.39 = 27.39
Base size at Level 1: 
𝑥 = Total Investment / Sum of Weights = 10,000 / 27.39 = 365.13
Position sizes =
Level 1: 365.13
Level 2: 547.70
Level 3: 821.55
...
Level 7: 11.39 * 365.13 = 4156.20

- Equal Martingale (Best for conservative strategies)
Calculation Logic:
Divide the total investment equally across all levels.
No increment or scaling; the position size is the same at each level.

Example:
Total Investment: RM 10,000
Grid Levels: 7
Step-by-Step Calculation:
Position size at each level: 
Size per Level = Total Investment / Grid Levels = 10,000 / 7 = 1428.57
Position sizes = 
Level 1:  1428.57
Level 2: 1428.57
...
Level 7: 
1428.57

## Implementing Martingale Logic

### Entry Conditions
- Place buy/sell orders when the price reaches specific grid levels.
- Ensure trade size follows the selected Martingale type.

### Exit Conditions
- Use take profit and stop loss based on grid levels.
- Optionally close all trades when reaching extreme grid boundaries.

### Logic Flow in Pseudocode
1. Read grid levels from the CSV file.
2. For each level in the grid:
   - Skip levels below the current price.
   - Check if a buy position already exists at this level.
   - Skip the level if a position exists.
   - Assign the lot size for the level.
3. Validate the lot size:
   - Ensure it is within broker-defined limits.
4. Place a buy order at the grid level with the assigned lot size.

Repeat until all grid levels are processed.

### Important Notes for csv file:
- File Location: The CSV file must be placed in the MQL5/Files/ directory of your MetaTrader 5 installation.
- CSV Format: This example assumes comma-separated values. If your CSV uses a different delimiter (like semicolon), change the ',' parameter in FileOpen().
- Columns: The example handles up to 100 columns per row. Adjust this if your CSV has more columns.
- Error Handling: The code checks for file opening errors and reports them.

### How to Improve the Strategy(Reduce Risk):
- Limit the number of steps (3-5 steps) -> to prevent catastrophic drawdowns
- Use smaller multipliers, instead of doubling use 1.2-1.5 -> reduce the exponential growth of lot sizes & slow down risk accumulation
- Apply maximum drawdown/Equity stop, set hard stop on account equity or floating drawdown -> prevents account wipeout
- For logic, combine with trend filter (stochastic/ADX) -> avoid trending market when martingale fails
  - ADX > 25 -> trend strength check
  - MA current - MA previous > 10*point -> confirm direction & steepness
  - BB width = upper - lower > 100*point -> detect volatility breakout
  - RSI > 70 OR RSI < 30 -> avoid extreme momentum zones
- Hedging/recovery techniques: partial close -> to reduce exposure while waiting for recovery
- Start with the smallest lot sizes, must start with 100
- Add take profit on basket -> reduce exposure time
- Use time-bases exit -> If the grid runs too long without recovery, close all trades at a controlled loss. This avoids “death by trend.”
- Diversify across pairs -> reduces the probability of total accont blow-up

### Averaging Price
Purpose of Averaging Price
- When you have multiple trades in a basket (due to martingale or grid), the break-even point shifts every time you add a new trade.
- To close the entire basket in profit, you need to know the weighted average entry price of all open positions.
- TP is then set relative to this average price so that when price reaches it, the combined profit (including all trades) is positive.

Why Not for Stop Loss or Lot Size
Stop Loss:
- Martingale/grid strategies rarely use SL per trade because the concept is to recover losses by adding positions.
- If you use a basket SL, it’s usually based on account risk, not average price.

Lot Size:
- Lot size progression (martingale) depends on the level or previous loss, not on average price.
- Example: Double lot size after each loss, regardless of average price.

### Averaging Down for Next Martingale Levels
Formula for Averaging Down
If you have:
- First buy: Lot size = L1, Price = P1
- Second buy: Lot size = L2, Price = P2

The average price after two buys is:
- Average Price = (L1 * P1) + (L2 * P2) / L1 + L2​
- To average down effectively, you increase L2 (the next lot size) so the average price moves closer to P2.

Formula for Next Level Price
- Percentage step: each next buy is 1% lower than the previous price. -> the percentage is input variable
- Price = Previous price * (1 - step%)
- For long entry:
  * Average price move down when lot size increase.
  * Average price move closer to next level price.
- For short entry:
  * Average price move up when lot size increase.

### Entry & Exit Logic for OBOS
- Based on multiple timeframe: short-term, mid-term, long-term
- Long Entry: Buy when oversold (stK < stD & mtK < mtD & ltK < ltD & stD < stOS & mtD < mtOS & ltD < ltOS)
- Long Exit: Sell when Overbought (stRSI > stOB-10 & mtRSI > mtOB-10 & ltOB-10)
- Short Entry: Sell when Overbought (stK > stD & mtK > mtD & ltK > ltD & stD > stOB & mtD > mtOB & ltD > ltOB)
- Short Exit: Buy when Oversold (stRSI < stOS+10 & mtRSI > mtOS+10 & ltOS+10)

### Entry & Exit Logic for ZooLogic
- Entry option: TREND, MOMENTUM, CONTRARIAN, CTRET (MODULES)
- Exit when: TREND or CTRET
