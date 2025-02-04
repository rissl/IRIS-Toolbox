function [s, field] = dat2str(dat, varargin)
% dat2str  Convert IRIS dates to cell array of strings
%{
% ## Syntax ##
%
%     S = dat2str(Dat, ...)
%
%
% ## Input Arguments ##
%
% __`Dat`__ [ numeric ] - 
% IRIS serial date number(s).
%
%
% ## Output Arguments ##
%
% __`S`__ [ cellstr ] - 
% Cellstr with strings representing the input dates.
%
%
% ## Options ##
%
% __`DateFormat='YYYYFP'`__ [ char | cellstr | string ] - 
% Date format string,
% or array of format strings (possibly different for each date).
%
% __`FreqLetters='YHQMW'`__ [ char | string ] - 
% Five letters used to
% represent the six possible frequencies of IRIS dates, in this order:
% yearly, half-yearly, quarterly, monthly, and weekly (such as the `'Q'` in
% `'2010Q1'`).
%
% __`Months={'January', ..., 'December'}`__ [ cellstr | string ] - 
% Twelve
% strings representing the names of the twelve months.
%
% __`ConversionMonth=1`__ [ numeric | `'last'` ] - 
% Month that will represent
% a lower-than-monthly-frequency date if the month is part of the date
% format string.
%
% __`WWDay='Thu'`__ [ `'Mon'` | `'Tue'` | `'Wed'` | `'Thu'` | `'Fri'` |
% `'Sat'` | `'Sun'` ] - 
% Day of week that will represent weeks.
%
%
% ## Description ##
%
% There are two types of date strings in IRIS: year-period strings and
% calendar date strings. The year-period strings can be printed for dates
% with yearly, half-yearly, quarterly, bimonthly, monthly, weekly, and
% indeterminate frequencies. The calendar date strings can be printed for
% dates with weekly and daily frequencies. Date formats for calendar date
% strings must start with a dollar sign, `$`.
%
% ### Year-Period Date Strings ###
%
% Regular date formats can include any combination of the following
% fields:
%
% * `'Y'` - One- to four-digit numeral representing a year.
%
% * `'YYYY'` - Four-digit numeral representing a year; padded with leading
% zeros if necessary.
%
% * `'YY'` - Two-digit numeral representing the last two digits of a year.
%
% * `'P'` - One- to two-digit numeral representing the period within the
% year (half-year, quarter, month, week).
%
% * `'PP'` - Two-digit numeral representing the period within the year,
% padded with leaading zeros if necessary.
%
% * `'R'` - Upper-case roman numeral for the period within the year.
%
% * `'r'` - Lower-case roman numeral for the period within the year.
%
% * `'M'` - One- to two-digit numeral representing a month.
%
% * `'MM'` - Two-digit numeral representing a month; padded with leading
% zeros if needed.
%
% * `'MMMM'`, `'Mmmm'`, `'mmmm'` - Case-sensitive full name of a month.
%
% * `'MMM'`, `'Mmm'`, `'mmm'` - Case-sensitive three-letter abbreviation of
% a month.
%
% * `'D'` - One- to two-digit numeral representing a day.
%
% * `'DD'` - Two-digit numeral representing a day; padded with zeros if
% necessary.
%
% * `'Q'` - Upper-case roman numeral representing a month or conversion month.
%
% * `'q'` - Lower-case roman numeral representing a month or conversion month.
%
% * `'F'` - Upper-case letter representing the date frequency.
%
% * `'f'` - Lower-case letter representing the date frequency.
%
% * `'EE'` - Two-digit numeral representing an end-of-month day; conversion
% month used for non-monthly dates; padded with zeros if necessary.
%
% * `'E'` - One- to two-digit numeral representing an end-of-month day;
% conversion month used for non-monthly dates; padded with zeros if
% necessary.
%
%
% ### Calendar Date Strings ###
%
% Calendar date formats must start with a dollar sign, `$`, and can include
% any combination of the following fields:
%
% * `'Y'` - Year.
%
% * `'YYYY'` - Four-digit year.
%
% * `'YY'` - Two-digit year.
%
% * `'DD'` - Two-digit day numeral; daily and weekly dates only.
%
% * `'D'` - Day numeral; daily and weekly dates only.
%
% * `'M'` - Month numeral.
%
% * `'MM'` - Two-digit month numeral.
%
% * `'MMMM'`, `'Mmmm'`, `'mmmm'` - Case-sensitive name of month.
%
% * `'MMM'`, `'Mmm'`, `'mmm'` - Case-sensitive three-letter abbreviation of
% month.
%
% * `'Q'` - Upper-case roman numeral for the month.
%
% * `'q'` - Lower-case roman numeral for the month.
%
% * `'DD'` - Two-digit day numeral.
%
% * `'D'` - Day numeral.
%
% * `'Aaa'`, `'AAA'` - Three-letter English name of the day of week
% (`'Mon'`, ..., `'Sun'`).
%
%
% ### Escaping Control Letters ###
%
% To get the format letters printed literally in the date string, use a
% percent sign as an escape character: `'%Y'`, `'%P'`, `'%F'`, `'%f'`, 
% `'%M'`, `'%m'`, `'%R'`, `'%r'`, `'%Q'`, `'%q'`, `'%D'`, `'%E'`, `'%D'`.
%
%
% ## Example ##
%
%}

% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2020 IRIS Solutions Team

persistent parser configStruct
if isempty(parser)
    configStruct = iris.get( );
    parser = extend.InputParser('dates.dat2str');
    parser.addRequired('InputDate', @(x) isa(x, 'DateWrapper') || isnumeric(x));
    parser.addDateOptions( );
end

% Bkw compatibility, called from within mydatxtick( ) and dbsave( )
if ~isempty(varargin) && isstruct(varargin{1})
    varargin = extend.InputParser.extractDateOptionsFromStruct(varargin{1});
end
parser.parse(dat, varargin{:});
opt = parser.Options;

upperRomans = { 'I', 'II', 'III', 'IV', 'V', 'VI', ...
                'VII', 'VIII', 'IX', 'X', 'XI', 'XII' };
lowerRomans = lower(upperRomans);

daysOfWeek = { 'Sunday', 'Monday', 'Tuesday', 'Wednesday', ...
               'Thursday', 'Friday', 'Saturday' };

%--------------------------------------------------------------------------

[year, per, freq] = dat2ypf(dat);

inxWeekly = freq==Frequency.WEEKLY;
inxDaily = freq==Frequency.DAILY;
inxMatlabSerial = inxWeekly | inxDaily;

% Matlab serial date numbers (daily or weekly dates only), calendar years, 
% months, and days.
msd = nan(size(dat));
yearC = nan(size(dat));
monC = nan(size(dat));
dayC = nan(size(dat));
dowC = nan(size(dat)); %% Day of week: 'Mon' through 'Sun'.
if any(inxMatlabSerial(:))
    msd(inxDaily) = dat(inxDaily);
    msd(inxWeekly) = ww2day(dat(inxWeekly), opt.WDay);
    [yearC(inxMatlabSerial), monC(inxMatlabSerial), dayC(inxMatlabSerial)] = datevec( double(msd(inxMatlabSerial)) );
    dowC(inxMatlabSerial) = weekday(msd(inxMatlabSerial));
end

s = cell(size(year));
s(:) = {''};
nDat = numel(year);
nFmt = numel(opt.DateFormat);
prevFreq = NaN;

for iDat = 1 : nDat
    ithDoubleDate = double(dat(iDat));
    if isequal(ithDoubleDate, Inf)
        s{iDat} = 'Inf';
        continue
    elseif isequal(ithDoubleDate, -Inf)
        s{iDat} = '-Inf';
        continue
    end

    ithFreq = freq(iDat);

    if iDat<=nFmt || ~isequaln(ithFreq, prevFreq)
        fmt = DateWrapper.chooseFormat(opt.DateFormat, ithFreq, min(iDat, nFmt));
        [fmt, field, isCalendar, isMonthNeeded] = parseDateFormat(fmt);
        numOfFields = length(field);
    end
    
    if ~any(ithFreq==configStruct.Freq)
        s{iDat} = 'Not-A-Date';
        continue
    end

    %{
    if ithFreq==Frequency.DAILY && ~isCalendar
        throw( exception.Base('Dates:CalendarFormatForDaily', 'error') );
    end
    %}

    subs = cell(1, numOfFields);
    subs(:) = {''};
    
    % Year-period
    iYear = year(iDat);
    iPer = per(iDat);
    iMsd = msd(iDat);
    iMon = NaN;

    % Calendar.
    iYearC = yearC(iDat);
    iMonC = monC(iDat);
    iDayC = dayC(iDat);
    iDowC = dowC(iDat);
    
    if ~isCalendar && isMonthNeeded
        % Calculate non-calendar month
        iMon = calculateMonth( );
    end
    
    for j = 1 : numOfFields
        switch field{j}(1)
            case {'Y', 'y'}
                if isCalendar
                    subs{j} = doYear(iYearC);
                else
                    subs{j} = doYear(iYear);
                end
            case {'M', 'm', 'Q', 'q'}
                if isCalendar
                    subs{j} = doMonth(iMonC);
                else
                    subs{j} = doMonth(iMon);
                end
            case {'P', 'R', 'r'}
                subs{j} = doPer( );
            case {'F', 'f'}
                subs{j} = subsFreqLetter( );
            case 'D'
                if isCalendar
                    subs{j} = doDay( );
                end
            case 'E'
                if isCalendar
                    subs{j} = doEom(iYearC, iMonC);
                else
                    subs{j} = doEom(iYear, iMon);
                end
            case 'W'
                if isCalendar
                    subs{j} = doEomW(iYearC, iMonC);
                else
                    subs{j} = doEomW(iYear, iMon);
                end
            case 'A'
                if isCalendar
                    subs{j} = doDow(iDowC);
                else
                    subs{j} = '';
                end
        end
    end
    
    s{iDat} = sprintf(fmt, subs{:});
    prevFreq = ithFreq;
end

return




    function [fmt, field, isCalendar, isMonthNeeded] = parseDateFormat(fmt)
        fmt = char(fmt);
        field = cell(1, 0);
        isCalendar = strncmp(fmt, '$', 1);
        if isCalendar
            fmt(1) = '';
        end
        isMonthNeeded = false;
        
        fragile = 'YyPFfRrQqMmEWDA';
        fmt = regexprep(fmt, ['%([', fragile, '])'], '&$1');
        
        ptn = ['(?<!&)(', ...
            'YYYY|YY|Y|yyyy|yy|y|', ...
            'PP|P|', ...
            'R|r|', ...
            'F|f|', ...
            'Mmmm|Mmm|mmmm|mmm|MMMM|MMM|MM|M|', ...
            'Q|q|', ...
            'EE|E|WW|W|', ...
            'DD|D|', ...
            'Aaa|AAA', ...
            ')'];
        
        while true
            found = false;
            replaceFunc = @replace; %#ok<NASGU>
            fmt = regexprep(fmt, ptn, '${replaceFunc($1)}', 'once');
            if ~found
                break
            end
        end
        
        fmt = regexprep(fmt, ['&([', fragile, '])'], '$1');
        
        return
        
        
        
        
        function c = replace(c0)
            found = true;
            c = '%s';
            field{end+1} = c0;
            if ~isCalendar && any(c0(1)=='MQqEW')
                isMonthNeeded = true;
            end
        end%
    end%




    function Subs = doYear(Y)
        Subs = '';
        if ~isfinite(Y)
            return
        end
        switch field{j}
            case {'YYYY', 'yyyy'}
                Subs = sprintf('%04g', Y);
            case {'YY', 'yy'}
                Subs = sprintf('%04g', Y);
                if length(Subs)>2
                    Subs = Subs(end-1:end);
                end
            case {'Y', 'y'}
                Subs = sprintf('%g', Y);
        end
    end% 




    function s = doPer( )
        s = '';
        if ~isfinite(iPer)
            return
        end
        switch field{j}
            case 'PP'
                s = sprintf('%02g', iPer);
            case 'P'
                if ithFreq<Frequency.MONTHLY
                    s = sprintf('%g', iPer);
                elseif ithFreq<Frequency.DAILY
                    s = sprintf('%02g', iPer);
                else
                    s = sprintf('%03g', iPer);
                end
            case 'R'
                try %#ok<TRYNC>
                    s = upperRomans{iPer};
                end
            case 'r'
                try %#ok<TRYNC>
                    s = lowerRomans{iPer};
                end
        end
    end%




    function s = doMonth(M)
        s = '';
        if ~isfinite(M)
            return
        end
        switch field{j}
            case {'MMMM', 'Mmmm', 'MMM', 'Mmm'}
                s = opt.Months{M};
                if field{j}(1)=='M'
                    s(1) = upper(s(1));
                else
                    s(1) = lower(s(1));
                end
                if field{j}(end)=='M'
                    s(2:end) = upper(s(2:end));
                else
                    s(2:end) = lower(s(2:end));
                end
                if length(field{j})==3
                    s = s(1:min(3, end));
                end
            case 'MM'
                s = sprintf('%02g', M);
            case 'M'
                s = sprintf('%g', M);
            case 'Q'
                try %#ok<TRYNC>
                    s = upperRomans{M};
                end
            case 'q'
                try %#ok<TRYNC>
                    s = lowerRomans{M};
                end
        end
    end%




    function subs = doDay( )
        subs = '';
        if ~isfinite(iDayC)
            return
        end
        switch field{j}
            case 'DD'
                subs = sprintf('%02g', iDayC);
            case 'D'
                subs = sprintf('%g', iDayC);
        end
    end%




    function subs = doEom(Y, M)
        subs = '';
        if ~isfinite(Y) || ~isfinite(M)
            return
        end
        e = eomday(Y, M);
        switch field{j}
            case 'E'
                subs = sprintf('%g', e);
            case 'EE'
                subs = sprintf('%02g', e);
        end
    end%




    function subs = doEomW(Y, M)
        subs = '';
        if ~isfinite(Y) || ~isfinite(M)
            return
        end
        e = eomday(Y, M);
        w = weekday(datenum(Y, M, e));
        if w==1
            e = e - 2;
        elseif w==7
            e = e - 1;
        end
        switch field{j}
            case 'W'
                subs = sprintf('%g', e);
            case 'WW'
                subs = sprintf('%02g', e);
        end
    end%




    function subs = doDow(A)
        subs = daysOfWeek{A};
        if strcmp(field{j}, 'Aaa')
            subs = subs(1:3);
        elseif strcmp(field{j}, 'AAA')
            subs = upper(subs(1:3));
        end
    end%




    function month = calculateMonth( )
        % Non-calendar month
        month = NaN;
        switch ithFreq
            case {Frequency.YEARLY, Frequency.HALFYEARLY, Frequency.QUARTERLY}
                month = per2month(iPer, ithFreq, opt.ConversionMonth);
            case Frequency.MONTHLY
                month = iPer;
            case Frequency.WEEKLY
                % Non-calendar month of a weekly date is the month that contains Thursday
                [~, month] = datevec( double(iMsd+3) );
        end
    end%




    function subs = subsFreqLetter( )
        subs = '';
        if ithFreq==Frequency.DAILY
            % TODO: Include daily freq letter in config
            subs = 'X';
        else
            inxRegular = ithFreq==configStruct.RegularFrequencies;
            if any(inxRegular)
                subs = opt.FreqLetters(inxRegular);
            end
        end
        if isequal(field{j}, 'f')
            subs = lower(subs);
        end
    end%
end%

