function write2DMetrics(file_path, metrics, metricsInfo, dispHeader,dispMetrics,padChar)
% 
% (C) Anton Milan, 2012-2013

fID = fopen(file_path,'w');

namesToDisplay=metricsInfo.names.long;
widthsToDisplay=metricsInfo.widths.long;
formatToDisplay=metricsInfo.format.long;

namesToDisplay=metricsInfo.names.short;
widthsToDisplay=metricsInfo.widths.short;
formatToDisplay=metricsInfo.format.short;

if nargin<4, dispHeader=1; end
if nargin<5
    dispMetrics=1:length(metrics);
end
if nargin<6
    padChar={' ',' ','|',' ',' ',' ','|',' ',' ',' ','| ',' ',' ',' '};
end

fprintf(fID,'\nEvaluation 2D:\n');

if dispHeader
    for m=dispMetrics
        printString=sprintf('fprintf(fID,''%%%is%s'',char(namesToDisplay(m)))',widthsToDisplay(m),char(padChar(m)));
        a = eval(printString);
    end
    fprintf(fID,'\n');
end

for m=dispMetrics
    printString=sprintf('fprintf(fID,''%%%i%s%s'',metrics(m))',widthsToDisplay(m),char(formatToDisplay(m)),char(padChar(m)));
    a = eval(printString);
end

% if standard, new line
if nargin<5
    fprintf(fID,'\n');
end

fclose(fID);