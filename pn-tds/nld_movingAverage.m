function [result,delay,movStd] = nld_movingAverage(data,ns)
%moving average over time data, pads data on both ends to fit original length
%% Metadata-----------------------------------------------------------
% Dagmar Krefting, 16.2.2015, dagmar.krefting@htw-berlin.de
% Version: 1.1
%-----------------------------------------------------------
%
%USAGE: nld_movingAverage(data,d)
% INPUT: 
% data  timeseries vector or matrix (col: signals, row: time)
% ns    number of samples to be averaged  
%
%OUTPUT:
% result  vector or matrix containing moving average with same length as
%           data
% delay   number of samples that are not averaged, but constant
%
%MODIFICATION LIST:
% v1.1 25.5.2017: Dagi: std added
%------------------------------------------------------------
%% calculate moving average
%number of samples excluding actual sample
ns = ns-1;
%dimensions of datarecord
dim = size(data);
%length of datarecord (number of rows)
l = dim(1);
%allocate buffer
result = zeros(l-ns,dim(2));

%length of datarecord is supposed to be on dim 1
for i = 1:l-ns
    result(i,:) = mean(data(i:i+ns,:));
    movStd(i,:) = std(data(i:i+ns,:));
end

%delay
delay = floor(ns/2);

%pad result with constant values (first and last averaged value
result = [repmat(result(1,:),delay,1); result; repmat(result(end,:),delay,1)];


    