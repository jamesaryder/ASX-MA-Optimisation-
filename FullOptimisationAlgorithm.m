%% Full optimisation algorithm

%% Running calculations for successful moving averages stocks

close all;
clear all;

asx_MAs = [];
asx200_test_results = [];
% asx_outcome_testing = [];

%% Optimisation Variables

optimisation_start_date = '1-Jan-2020';
optimisation_end_date = '1-Aug-2020';

optimisation_period = 60;

lower_envelope_percent = 5;

polydegree = 6;

%% Read .csv files for asx200 companies and download data  
    
asx200_tickers_table = readtable('Envelope_Success_Companies.csv');
asx200_tickers = table2cell(asx200_tickers_table);

%% Initially download data from asx200 ticker stock to get trading days

ticker = '^AXJO';
start_date = optimisation_start_date;
end_date = optimisation_end_date;
initDate = start_date;
symbol = ticker;
aaplusd_yahoo_raw = getMarketDataViaYahoo(symbol, initDate);
aaplusd_yahoo= timeseries([aaplusd_yahoo_raw.Close, aaplusd_yahoo_raw.High, aaplusd_yahoo_raw.Low], datestr(aaplusd_yahoo_raw(:,1).Date));
aaplusd_yahoo.DataInfo.Units = 'USD';
aaplusd_yahoo.Name = symbol;
aaplusd_yahoo.TimeInfo.Format = "dd-mm-yyyy";
price_history_draft = aaplusd_yahoo_raw{:,2:end};
dates_formating = datenum(aaplusd_yahoo_raw.Date);
price_history = [dates_formating price_history_draft];

% Remove data after end date however keep the final day + 1 price for later

if isempty(end_date) == 0

    end_datenum = datenum(end_date);
    dates_extract = price_history(:,1);
    index_remove = find(dates_extract > end_datenum,1);    
    price_history(index_remove:end,:) = [];
    
end

optimisation_dates = dates_formating;

%% Return to ticker loop
daytoday_outcomes = zeros(length(asx200_tickers),length(optimisation_dates));
optimised_MAs = zeros(length(asx200_tickers),length(optimisation_dates));

errors = 0;

itterations = length(asx200_tickers)*length(optimisation_dates);
itterations_remaining = itterations;
tic;

print_day_result = zeros(1,length(optimisation_dates));

for date_loop = 1:length(optimisation_dates)

    optimisation_date = optimisation_dates(date_loop);
    
for ticker_loop = 1:length(asx200_tickers)

   
ticker = asx200_tickers{ticker_loop};
start_date = datetime(optimisation_date-optimisation_period, 'ConvertFrom', 'datenum', 'Format', 'dd-MMM-yyyy');
end_date = datetime(optimisation_date, 'ConvertFrom', 'datenum', 'Format', 'dd-MMM-yyyy');

% Download Data

try

initDate = start_date;
symbol = ticker;
aaplusd_yahoo_raw = getMarketDataViaYahoo(symbol, initDate);
aaplusd_yahoo= timeseries([aaplusd_yahoo_raw.Close, aaplusd_yahoo_raw.High, aaplusd_yahoo_raw.Low], datestr(aaplusd_yahoo_raw(:,1).Date));
aaplusd_yahoo.DataInfo.Units = 'USD';
aaplusd_yahoo.Name = symbol;
aaplusd_yahoo.TimeInfo.Format = "dd-mm-yyyy";

catch 
    
    errors = errors + 1;
    itterations_remaining = itterations_remaining - 1;
    time_remaining = toc/(itterations-itterations_remaining)*itterations_remaining;
    clc;
    fprintf('Time Remaining: %.2f\n',time_remaining/60);
    fprintf('Itterations Remaining: %d\n',itterations_remaining);
    fprintf('Errors: %d\n',errors);
    
    print_day_result(date_loop) = print_day_result(date_loop-1);
    
    continue;
    
end

price_history_draft = aaplusd_yahoo_raw{:,2:end};
dates_formating = datenum(aaplusd_yahoo_raw.Date);
price_history = [dates_formating price_history_draft];

% Remove data after end date 

if isempty(end_date) == 0

    end_datenum = datenum(end_date);
    dates_extract = price_history(:,1);
    index_remove = find(dates_extract > end_datenum,1);
    
    future_price = price_history(index_remove,5);
    
    price_history(index_remove:end,:) = [];
    
end
%% Compute moving averages

ma_periods = 1:50;

[rows,cols] = size(price_history);

MA = zeros(rows,length(ma_periods)+1);

for day = 1:rows
    
    % Save close price
    
    MA(day,1) = price_history(day,5);
    
    % Loop through moving average periods
    
    for i = 1:length(ma_periods)
        
        if day >= ma_periods(i)
            
            % Save moving average
            
            MA(day,i+1) = mean(MA((day-ma_periods(i)+1):day,1));
            
        end
        
    end
    
end

%% Buy and Sell at Upper Limit of Envelope

legend_numbers = {};

trade_outcome = [];

for envelope_ma = 1:50
    
        index_envelope = find(ma_periods == envelope_ma);
        
        buy_price = [];
        sell_price = [];
        trade_profit = [];

        for day = envelope_ma:rows

            if MA(day,1) > MA(day,index_envelope+1)*(1+lower_envelope_percent/100) && isempty(buy_price) == 1 

                buy_price = MA(day,1);
                %datestr(datetime(dates_formating(day), 'ConvertFrom', 'datenum', 'Format', 'dd-MMM-yyyy'))
                
            elseif MA(day,1) < MA(day,index_envelope+1)*(1+lower_envelope_percent/100) && isempty(buy_price) == 0 

                sell_price = MA(day,1);
                %datestr(datetime(dates_formating(day), 'ConvertFrom', 'datenum', 'Format', 'dd-MMM-yyyy'))
                
                perc_chg = (sell_price-buy_price)/buy_price+1;

                trade_profit = [trade_profit,perc_chg];

                buy_price = [];
                sell_price = [];

            end 
        
        end
        
        if isempty(trade_profit) == 1
            
            trade_profit = 0;
            
        end
    
        count_positive = length(trade_profit(trade_profit>1));
        count_purchases = length(trade_profit);
        success_rate = count_positive/count_purchases*100;
        expected_return = (prod(trade_profit)-1)*success_rate;
    
        trade_outcome = [trade_outcome;[envelope_ma,(prod(trade_profit)-1)*100,success_rate,count_purchases,expected_return]]; 
        
               
end

coeffs = polyfit(trade_outcome(:,1),trade_outcome(:,5),polydegree);
yfit = polyval(coeffs,trade_outcome(:,1));
[fit_value,fit_index] = max(yfit);

%% Find result for next day of trade

%envelope_ma_optimised = round(fit_index);
[max_value,max_index] = max(trade_outcome(:,5));
envelope_ma_optimised = max_index;

if MA(rows,1) > MA(rows,envelope_ma_optimised+1)*(1+lower_envelope_percent/100)
    
    daytoday_outcomes(ticker_loop,date_loop) = (future_price - MA(rows,1))/MA(rows,1)*100;
    optimised_MAs(ticker_loop,date_loop) = envelope_ma_optimised;
    
end

% Output time remaining

itterations_remaining = itterations_remaining - 1;
time_remaining = toc/(itterations-itterations_remaining)*itterations_remaining;
clc;
fprintf('Time Remaining: %.2f\n',time_remaining/60);
fprintf('Itterations Remaining: %d\n',itterations_remaining);
fprintf('Errors: %d\n',errors);

end

% Ongoing graph results

ongoing_outcome = daytoday_outcomes;
ongoing_outcome = (ongoing_outcome + 100)./100;

print_day_result(date_loop) = (prod(prod(ongoing_outcome))-1).*100;

% Plot of optimisation outcome progress
clf;
figure(1)
plot(1:date_loop,print_day_result(1:date_loop));
xlabel('Days');
ylabel('Outcome (%)');
xlim([0 length(optimisation_dates)])
grid on
grid minor
hold on
drawnow

end
