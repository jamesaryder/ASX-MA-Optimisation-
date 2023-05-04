%% Stock Market Practice Simulator

clear all;
clc;
close all;

%% Simulator Variables

ticker = 'NWH.AX';
start_date = '1-Jan-2019';
end_date = '1-Jan-2020';

visualised_days = 30;
plotted_ma = 12;

brokerage_fee = 20;
starting_cash = 12500;


%% Download Data

asx_MAs = [];
asx_outcome_testing = [];

data_backlog = 75;

initDate = datetime(datenum(start_date)-data_backlog, 'ConvertFrom', 'datenum', 'Format', 'dd-MMM-yyyy');
symbol = ticker;
aaplusd_yahoo_raw = getMarketDataViaYahoo(symbol, initDate);
aaplusd_yahoo= timeseries([aaplusd_yahoo_raw.Close, aaplusd_yahoo_raw.High, aaplusd_yahoo_raw.Low], datestr(aaplusd_yahoo_raw(:,1).Date));
aaplusd_yahoo.DataInfo.Units = 'USD';
aaplusd_yahoo.Name = symbol;
aaplusd_yahoo.TimeInfo.Format = "dd-mm-yyyy";

price_history_draft = aaplusd_yahoo_raw{:,2:end};
dates_formating = datenum(aaplusd_yahoo_raw.Date);
price_history = [dates_formating price_history_draft];

% Remove data after end date 

if isempty(end_date) == 0

    end_datenum = datenum(end_date);
    dates_extract = price_history(:,1);
    index_remove = find(dates_extract > end_datenum,1);
    
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

%% Begin Testing

sim_start_num = datenum(start_date);
last_day_index = rows;
first_day_index = find(dates_extract >= sim_start_num,1);

% Set parameter for if holding shares
holding = 0;
cash = starting_cash;
shares_held = 0;

for sim_day = first_day_index:last_day_index
    
    % Plot for user
    
    for i = visualised_days:-1:1

    %MA_perc_diff_plot(i) = (MA(end+1-i,current_high_ma+1)-MA(end+1-i,current_low_ma+1))/MA(end+1-i,current_low_ma+1)*100;
    MA_perc_diff_plot(i) = MA(sim_day+1-i,plotted_ma+1);
    plot_price(i) = MA(sim_day+1-i,1);

    end

    figure(1)
    plot(visualised_days:-1:1,MA_perc_diff_plot)
    hold on
    plot(visualised_days:-1:1,plot_price)
    xlabel('Days from Today');
    ylabel('Price ($)')
    grid on
    grid minor
    title(datestr(datetime(dates_extract(sim_day), 'ConvertFrom', 'datenum', 'Format', 'dd-MMM-yyyy')));
    
    % Request input from user
    
    today_price = MA(sim_day,1);
    
    fprintf('Portfolio Value: $ %.2f\n',cash+today_price*shares_held);
    fprintf('Shares Held: %.2f\n',shares_held);
    
    if holding == 0
                 
        user_request = input('Enter B to Buy: ','s');
        
        if user_request == 'B'
            
            shares_held = cash/today_price;
            cash = 0;
            holding = 1;
            
        end
        
    elseif holding == 1
        
        user_request = input('Enter S to Sell: ','s');
        
        if user_request == 'S'
            
            cash = shares_held*today_price;
            shares_held = 0;
            holding = 0;
            
        end
        
    end
        
    
    clf;
    
end



%% Plot Results


% % Find percentage difference between current high and low MA
% 
% current_high_ma = asx200_tickers{ticker_loop,2};
% current_low_ma = asx200_tickers{ticker_loop,3};
% MA_perc_diff = (MA(end,current_high_ma+1)-MA(end,current_low_ma+1))/MA(end,current_low_ma+1)*100;
% 
%     Mach_solve.objective = @(p) (MA(end,current_high_ma)*(current_high_ma-1)+p)/current_high_ma-(MA(end,current_low_ma)*(current_low_ma-1)+p)/current_low_ma;
%     Mach_solve.solver = 'fzero';
%     Mach_solve.options = optimset('fzero');
%     Mach_solve.x0 = [-1 100];
%     ptrade = fzero(Mach_solve);
% 
% pcurrent = MA(end,1);
%     
% asx_MAs = [asx_MAs;MA_perc_diff/100,pcurrent,ptrade]; %min including because issue of two maxs
% 
% days_visualised = 40;
% 
% for i = days_visualised:-1:1
% 
% MA_perc_diff_plot(i) = (MA(end+1-i,current_high_ma+1)-MA(end+1-i,current_low_ma+1))/MA(end+1-i,current_low_ma+1)*100;
% plot_price(i) = MA(end+1-i,1);
% 
% end
% 
% figure(ticker_loop)
% yyaxis left
% plot(days_visualised:-1:1,MA_perc_diff_plot)
% xlabel('Days from Today');
% ylabel('Difference of MA');
% yyaxis right
% plot(days_visualised:-1:1,plot_price)
% ylabel('Price ($)')
% title(ticker);